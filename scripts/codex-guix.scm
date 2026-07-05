#!/usr/bin/env -S guile -s
!#

(use-modules (ice-9 format)
             (srfi srfi-1)
             (srfi srfi-13))

(define home
  (or (getenv "HOME")
      (begin
        (format (current-error-port) "codex-guix: HOME is not set.~%")
        (exit 1))))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/codex.scm"))

(define (mode-name mode)
  (if (eq? mode 'full) "full" "sandbox"))

(define (expand-user-path path)
  (cond
    ((string=? path "~") home)
    ((string-prefix? "~/" path)
     (string-append home (substring path 1)))
    (else path)))

(define (usage)
  (format #t "Usage: codex-guix [--full|--sandbox] [MANIFEST-PATH] [-- CODEX-ARGS...]~%")
  (format #t "Default mode: full. Pass --sandbox for a contained Guix shell.~%")
  (format #t "Default manifest: ~a~%" default-manifest)
  (format #t "Unknown options are passed to Codex. Use -- before Codex args when ambiguous.~%"))

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
  (let loop ((rest args) (mode 'full) (manifest #f))
    (cond
      ((null? rest)
       (values mode (or manifest default-manifest) '()))
      ((member (car rest) '("-h" "--help"))
       (usage)
       (exit 0))
      ((string=? (car rest) "--")
       (values mode (or manifest default-manifest) (cdr rest)))
      ((string=? (car rest) "--full")
       (loop (cdr rest) 'full manifest))
      ((string=? (car rest) "--sandbox")
       (loop (cdr rest) 'sandbox manifest))
      ((string-prefix? "-" (car rest))
       (values mode (or manifest default-manifest) rest))
      ((not manifest)
       (loop (cdr rest) mode (expand-user-path (car rest))))
      (else
       (values mode manifest rest)))))

(define (guix-args mode manifest codex-args)
  (append
   (if (eq? mode 'sandbox)
       (append
        '("shell" "--container" "--nesting" "--network")
        (maybe-mount "--expose"
                     (string-append home "/.config/git/config")
                     (string-append home "/.config/git/config"))
        (maybe-mount "--expose"
                     (string-append home "/.gitconfig")
                     (string-append home "/.gitconfig"))
        ;; Persist Codex auth/config
        (maybe-mount "--share"
                     (string-append home "/.codex")
                     (string-append home "/.codex"))
        ;; Persist npm global install location
        (maybe-mount "--share"
                     (string-append home "/.local")
                     (string-append home "/.local"))
        ;; Host Docker/Podman sockets for container-backed tools.
        (container-socket-mounts)
        ;; Optional: preserve pnpm caches later if you switch back to pnpm
        ;; (maybe-mount "--share"
        ;;              (string-append home "/.cache/pnpm")
        ;;              (string-append home "/.cache/pnpm"))
        ;; (maybe-mount "--share"
        ;;              (string-append home "/.local/share/pnpm")
        ;;              (string-append home "/.local/share/pnpm"))
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
       '("shell"))
   (list "-m" manifest)
   (list "--" "bash" "-c"
         (string-append
          "export SHELL=$(command -v bash); "
          "export NPM_CONFIG_PREFIX=\"$HOME/.local\"; "
          "export PATH=\"$HOME/.local/bin:$PATH\"; "
          "if [ ! -f \"$HOME/.local/lib/node_modules/@openai/codex/bin/codex.js\" ]; then "
          "  npm install -g @openai/codex; "
          "fi; "
          "exec node \"$HOME/.local/lib/node_modules/@openai/codex/bin/codex.js\" \"$@\"")
         "codex-guix")
   codex-args))

(define (main)
  (call-with-values
    (lambda () (parse-args (cdr (command-line))))
    (lambda (mode manifest codex-args)
      (unless (file-exists? manifest)
        (format (current-error-port)
                "codex-guix: manifest not found: ~a~%" manifest)
        (exit 1))

      (format #t "codex-guix: mode: ~a~%" (mode-name mode))
      (format #t "codex-guix: using manifest: ~a~%" manifest)
      (unless (null? codex-args)
        (format #t "codex-guix: codex args: ~a~%" (string-join codex-args " ")))

      (let ((status (apply system* "guix" (guix-args mode manifest codex-args))))
        (if (zero? status)
            (exit 0)
            (begin
              (format (current-error-port)
                      "codex-guix: guix shell exited with status ~a~%" status)
              (exit 1)))))))

(main)
