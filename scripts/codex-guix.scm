#!/usr/bin/env -S guile -s
!#

(eval-when (expand load eval)
  (add-to-load-path
   (string-append (dirname (canonicalize-path (car (command-line)))) "/lib")))

(use-modules (agent-launch)
             (ice-9 format)
             (srfi srfi-1)
             (srfi srfi-13))

(define home (require-home "codex-guix"))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/codex.scm"))

(define (usage)
  (format #t "Usage: codex-guix [--full|--sandbox] [MANIFEST-PATH] [-- CODEX-ARGS...]~%")
  (format #t "Default mode: full. Pass --sandbox for a contained Guix shell.~%")
  (format #t "Default manifest: ~a~%" default-manifest)
  (format #t "Unknown options are passed to Codex. Use -- before Codex args when ambiguous.~%"))

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

(define (guix-args mode manifest codex-args)
  (append
   (if (eq? mode 'sandbox)
       (append
        '("shell" "--container" "--nesting" "--network")
        (git-config-mounts home)
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
        (xdg-runtime-expose)
        (guix-profiles-expose)
        (preserve-common-env))
       '("shell"))
   (list "-m" manifest)
   (list "--" "bash" "-c"
         (string-append
          "export SHELL=$(command -v bash); "
          ;; Reuse the manifest's python instead of downloading a standalone one.
          "export UV_PYTHON_PREFERENCE=system; "
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

      (run-guix "codex-guix" (guix-args mode manifest codex-args)))))

(main)
