#!/usr/bin/env -S guile -s
!#

(use-modules (ice-9 format)
             (ice-9 popen)
             (srfi srfi-1)
             (srfi srfi-13))

(define (env name default)
  (or (getenv name) default))

(define home
  (or (getenv "HOME")
      (begin
        (format (current-error-port) "claude-guix: HOME is not set.~%")
        (exit 1))))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/claude.scm"))

(define (mode-name mode)
  (if (eq? mode 'full) "full" "sandbox"))

(define (expand-user-path path)
  (cond
    ((string=? path "~") home)
    ((string-prefix? "~/" path)
     (string-append home (substring path 1)))
    (else path)))

(define (resolve-directory path)
  (if (string-prefix? "/" path)
      path
      (string-append (getcwd) "/" path)))

(define (usage)
  (format #t "Usage: claude-guix [--full|--sandbox] [PROJECT-DIR] [-m MANIFEST-PATH]... [-- CLAUDE-ARGS...]~%")
  (format #t "       claude-guix --resume SESSION-ID~%")
  (format #t "  Default mode: full. Pass --sandbox for a project-only Guix shell.~%")
  (format #t "  PROJECT-DIR defaults to the current directory.~%")
  (format #t "  -m may be given multiple times; each manifest is layered~%")
  (format #t "     on top of the base manifest: ~a~%" default-manifest)
  (format #t "  Unknown options are passed to Claude. Use -- before Claude args when ambiguous.~%"))

(define (maybe-mount flag source target)
  (if (and source (file-exists? source))
      (list (string-append flag "=" source "=" target))
      '()))

(define (maybe-preserve name)
  (if (getenv name)
      (list (string-append "--preserve=^" name "$"))
      '()))

(define (container-socket-mounts)
  (append
   (maybe-mount "--expose" "/var/run/docker.sock" "/var/run/docker.sock")
   (let ((xdg-runtime (getenv "XDG_RUNTIME_DIR")))
     (if xdg-runtime
         (append
          (maybe-mount "--expose"
                       (string-append xdg-runtime "/docker.sock")
                       (string-append xdg-runtime "/docker.sock"))
          (maybe-mount "--expose"
                       (string-append xdg-runtime "/podman/podman.sock")
                       (string-append xdg-runtime "/podman/podman.sock")))
         '()))))

(define (parse-args args)
  ;; extra-manifests accumulates user -m paths (in order); the base manifest
  ;; is always included so bash/node/pnpm/git are present in the profile.
  (let loop ((rest args) (mode 'full) (project #f) (extra-manifests '()) (claude-args '()))
    (cond
      ((null? rest)
       (values mode (or project (getcwd)) (reverse extra-manifests)
               (reverse claude-args)))
      ((member (car rest) '("-h" "--help"))
       (usage)
       (exit 0))
      ((string=? (car rest) "--")
       (values mode (or project (getcwd)) (reverse extra-manifests)
               (append (reverse claude-args) (cdr rest))))
      ((string=? (car rest) "--full")
       (loop (cdr rest) 'full project extra-manifests claude-args))
      ((string=? (car rest) "--sandbox")
       (loop (cdr rest) 'sandbox project extra-manifests claude-args))
      ((and (string=? (car rest) "-m") (pair? (cdr rest)))
       (loop (cddr rest) mode project
             (cons (resolve-directory (expand-user-path (cadr rest))) extra-manifests)
             claude-args))
      ((string-prefix? "-" (car rest))
       (values mode (or project (getcwd)) (reverse extra-manifests) rest))
      ((not project)
       (loop (cdr rest) mode (resolve-directory (expand-user-path (car rest))) extra-manifests claude-args))
      (else
       (values mode project (reverse extra-manifests) rest)))))

(define (manifest-args manifests)
  (append-map (lambda (m) (list "-m" m)) manifests))

(define (ensure-directory path)
  (unless (file-exists? path)
    (mkdir path)))

(define (guix-args mode extra-manifests project-dir claude-args)
  (ensure-directory (string-append home "/.claude"))
  (ensure-directory (string-append home "/.cache/pnpm"))
  (ensure-directory (string-append home "/.local/share/pnpm"))
  (ensure-directory (string-append home "/.local/share/pnpm/bin"))
  (let ((cmd (string-append
              "export SHELL=$(command -v bash); "
              "export PNPM_HOME=\"$HOME/.local/share/pnpm\"; "
              "export PATH=\"$PNPM_HOME/bin:$PNPM_HOME:$PATH\"; "
              "cd "
              (format #f "~s" project-dir)
              " && pnpm add -g @anthropic-ai/claude-code@latest"
              " && exec claude --dangerously-skip-permissions \"$@\"")))
    (append
     (append
      '("shell" "--container" "--emulate-fhs" "--nesting" "--network")
      (if (eq? mode 'sandbox)
          ;; project directory (read-write)
          (list (string-append "--share=" project-dir "=" project-dir))
          ;; full mode needs an FHS container for Claude's native binary, but it
          ;; keeps the user's home writable so normal project access still works.
          (list (string-append "--share=" home "=" home)))
      (if (eq? mode 'sandbox)
          (append
           ;; git config (read-only)
           (maybe-mount "--expose"
                        (string-append home "/.config/git/config")
                        (string-append home "/.config/git/config"))
           (maybe-mount "--expose"
                        (string-append home "/.gitconfig")
                        (string-append home "/.gitconfig"))
           ;; claude credentials and state (read-write)
           (list (string-append "--share=" home "/.claude=" home "/.claude"))
           (maybe-mount "--share"
                        (string-append home "/.claude.json")
                        (string-append home "/.claude.json"))
           ;; pnpm caches (read-write)
           (list (string-append "--share=" home "/.cache/pnpm=" home "/.cache/pnpm"))
           (list (string-append "--share=" home "/.local/share/pnpm=" home "/.local/share/pnpm")))
          '())
      ;; Host Docker/Podman sockets for container-backed tools.
      (container-socket-mounts)
      ;; runtime / display
      (let ((xdg-runtime (getenv "XDG_RUNTIME_DIR")))
        (if (and xdg-runtime (file-exists? xdg-runtime))
            (list (string-append "--expose=" xdg-runtime "=" xdg-runtime))
            '()))
      (maybe-preserve "DBUS_SESSION_BUS_ADDRESS")
      (maybe-preserve "COLORTERM")
      (maybe-preserve "CONTAINER_HOST")
      (maybe-preserve "DISPLAY")
      (maybe-preserve "DOCKER_HOST")
      (maybe-preserve "WAYLAND_DISPLAY")
      (maybe-preserve "XDG_RUNTIME_DIR")
      (maybe-preserve "XAUTHORITY"))
     (manifest-args (cons default-manifest extra-manifests))
     (list "--" "bash" "-c" cmd "claude-guix")
     claude-args)))

(define (main)
  (call-with-values
    (lambda () (parse-args (cdr (command-line))))
    (lambda (mode project-dir extra-manifests claude-args)
      (for-each
       (lambda (m)
         (unless (file-exists? m)
           (format (current-error-port)
                   "claude-guix: manifest not found: ~a~%" m)
           (exit 1)))
       (cons default-manifest extra-manifests))
      (unless (file-exists? project-dir)
        (format (current-error-port)
                "claude-guix: project directory not found: ~a~%" project-dir)
        (exit 1))

      (format #t "claude-guix: mode: ~a~%" (mode-name mode))
      (format #t "claude-guix: project: ~a~%" project-dir)
      (format #t "claude-guix: manifests: ~a~%"
              (string-join (cons default-manifest extra-manifests) " "))
      (unless (null? claude-args)
        (format #t "claude-guix: claude args: ~a~%" (string-join claude-args " ")))

      (let ((status (apply system* "guix" (guix-args mode extra-manifests project-dir claude-args))))
        (if (zero? status)
            (exit 0)
            (begin
              (format (current-error-port)
                      "claude-guix: guix shell exited with status ~a~%" status)
              (exit 1)))))))

(main)
