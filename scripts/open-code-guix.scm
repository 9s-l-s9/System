#!/usr/bin/env -S guile -s
!#

(use-modules (ice-9 format)
             (srfi srfi-1)
             (srfi srfi-13))

(define (env name default)
  (or (getenv name) default))

(define home
  (or (getenv "HOME")
      (begin
        (format (current-error-port) "opencode-guix: HOME is not set.~%")
        (exit 1))))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/claude.scm"))

(define (expand-user-path path)
  (cond
    ((string=? path "~") home)
    ((string-prefix? "~/" path)
     (string-append home (substring path 1)))
    (else path)))

(define (usage)
  (format #t "Usage: opencode-guix [MANIFEST-PATH]~%")
  (format #t "Default manifest: ~a~%" default-manifest))

(define (maybe-mount flag source target)
  (if (and source (file-exists? source))
      (list (string-append flag "=" source "=" target))
      '()))

(define (maybe-preserve name)
  (if (getenv name)
      (list (string-append "--preserve=^" name "$"))
      '()))

(define (manifest-path-from-args args)
  (cond
    ((null? args) default-manifest)
    ((member (car args) '("-h" "--help"))
     (usage)
     (exit 0))
    ((= (length args) 1)
     (expand-user-path (car args)))
    (else
     (usage)
     (format (current-error-port)
             "opencode-guix: expected at most one manifest path argument.~%")
     (exit 1))))

(define (guix-args manifest)
  (append
   '("shell" "--container" "--nesting" "--emulate-fhs" "--network")
   (maybe-mount "--expose"
                (string-append home "/.config/git/config")
                (string-append home "/.config/git/config"))
   (maybe-mount "--share"
                (string-append home "/.config/opencode")
                (string-append home "/.config/opencode"))
   (maybe-mount "--share"
                (string-append home "/.cache/pnpm")
                (string-append home "/.cache/pnpm"))
   (maybe-mount "--share"
                (string-append home "/.local/share/pnpm")
                (string-append home "/.local/share/pnpm"))
   (let ((xdg-runtime (getenv "XDG_RUNTIME_DIR")))
     (if (and xdg-runtime (file-exists? xdg-runtime))
         (list (string-append "--expose=" xdg-runtime "=" xdg-runtime))
         '()))
   (maybe-preserve "DBUS_SESSION_BUS_ADDRESS")
   (maybe-preserve "COLORTERM")
   (maybe-preserve "DISPLAY")
   (maybe-preserve "WAYLAND_DISPLAY")
   (maybe-preserve "XAUTHORITY")
   (list "-m" manifest)
   '("--"
     "bash" "-lc"
     "export SHELL=$(command -v bash); exec npx -y opencode-ai")))

(define (main)
  (let* ((args (cdr (command-line)))
         (manifest (manifest-path-from-args args)))
    (unless (file-exists? manifest)
      (format (current-error-port)
              "opencode-guix: manifest not found: ~a~%" manifest)
      (exit 1))

    (format #t "opencode-guix: using manifest: ~a~%" manifest)

    (let ((status (apply system* "guix" (guix-args manifest))))
      (if (zero? status)
          (exit 0)
          (begin
            (format (current-error-port)
                    "opencode-guix: guix shell exited with status ~a~%" status)
            (exit 1))))))

(main)
