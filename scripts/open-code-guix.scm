#!/usr/bin/env -S guile -s
!#

(eval-when (expand load eval)
  (add-to-load-path
   (string-append (dirname (canonicalize-path (car (command-line)))) "/lib")))

(use-modules (agent-launch)
             (ice-9 format)
             (srfi srfi-1)
             (srfi srfi-13))

(define home (require-home "opencode-guix"))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/claude.scm"))

(define (usage)
  (format #t "Usage: opencode-guix [--full|--sandbox] [MANIFEST-PATH] [-- OPENCODE-ARGS...]~%")
  (format #t "Default mode: full. Pass --sandbox for a contained Guix shell.~%")
  (format #t "Default manifest: ~a~%" default-manifest)
  (format #t "Unknown options are passed to OpenCode. Use -- before OpenCode args when ambiguous.~%"))

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
       (loop (cdr rest) mode (expand-user-path home (car rest))))
      (else
       (values mode manifest rest)))))

(define (guix-args mode manifest opencode-args)
  (append
   (if (eq? mode 'sandbox)
       (append
        '("shell" "--container" "--nesting" "--emulate-fhs" "--network")
        (git-config-mounts home)
        (maybe-mount "--share"
                     (string-append home "/.config/opencode")
                     (string-append home "/.config/opencode"))
        (maybe-mount "--share"
                     (string-append home "/.cache/pnpm")
                     (string-append home "/.cache/pnpm"))
        (maybe-mount "--share"
                     (string-append home "/.local/share/pnpm")
                     (string-append home "/.local/share/pnpm"))
        ;; Host Docker/Podman sockets for container-backed tools.
        (container-socket-mounts)
        (xdg-runtime-expose)
        (guix-profiles-expose)
        (preserve-common-env))
       '("shell"))
   (list "-m" manifest)
   '("--"
     "bash" "-c"
     "export SHELL=$(command -v bash); export UV_PYTHON_PREFERENCE=system; exec npx -y opencode-ai \"$@\""
     "opencode-guix")
   opencode-args))

(define (main)
  (call-with-values
    (lambda () (parse-args (cdr (command-line))))
    (lambda (mode manifest opencode-args)
      (unless (file-exists? manifest)
        (format (current-error-port)
                "opencode-guix: manifest not found: ~a~%" manifest)
        (exit 1))

      (format #t "opencode-guix: mode: ~a~%" (mode-name mode))
      (format #t "opencode-guix: using manifest: ~a~%" manifest)
      (unless (null? opencode-args)
        (format #t "opencode-guix: opencode args: ~a~%" (string-join opencode-args " ")))

      (run-guix "opencode-guix" (guix-args mode manifest opencode-args)))))

(main)
