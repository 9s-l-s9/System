#!/usr/bin/env -S guile -s
!#

(eval-when (expand load eval)
  (add-to-load-path
   (string-append (dirname (canonicalize-path (car (command-line)))) "/lib")))

(use-modules (agent-launch)
             (ice-9 format)
             (ice-9 popen)
             (srfi srfi-1)
             (srfi srfi-13))

(define home (require-home "pi-guix"))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/pi.scm"))

(define (usage)
  (format #t "Usage: pi-guix [--full|--sandbox] [MANIFEST-PATH] [-- PI-ARGS...]~%")
  (format #t "Default mode: full. Pass --sandbox for a contained Guix shell.~%")
  (format #t "Default manifest: ~a~%" default-manifest)
  (format #t "Unknown options are passed to Pi. Use -- before Pi args when ambiguous.~%"))

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

(define (guix-args mode manifest pi-args)
  (ensure-directory (string-append home "/.cache"))
  (ensure-directory (string-append home "/.pi"))
  (ensure-directory (string-append home "/.local"))
  (ensure-directory (string-append home "/.local/share"))
  (ensure-directory (string-append home "/.cache/pnpm"))
  (ensure-directory (string-append home "/.local/share/pnpm"))
  (ensure-directory (string-append home "/.local/share/pnpm/bin"))
  (append
   (if (eq? mode 'sandbox)
       (append
        '("shell" "--container" "--emulate-fhs" "--nesting" "--network")
        ;; Git identity (read-only)
        (git-config-mounts home)
        ;; Pi auth, sessions, and settings (~/.pi/agent/auth.json etc.)
        (maybe-mount "--share"
                     (string-append home "/.pi")
                     (string-append home "/.pi"))
        ;; pnpm package cache (avoids re-downloading @mariozechner/pi-coding-agent)
        (maybe-mount "--share"
                     (string-append home "/.cache/pnpm")
                     (string-append home "/.cache/pnpm"))
        (maybe-mount "--share"
                     (string-append home "/.local/share/pnpm")
                     (string-append home "/.local/share/pnpm"))
        ;; Host Docker/Podman sockets for container-backed tools.
        (container-socket-mounts)
        ;; XDG runtime (dbus, wayland socket)
        (xdg-runtime-expose)
        (guix-profiles-expose)
        (preserve-common-env))
       '("shell"))
   (list "-m" manifest)
   (list "--"
         "bash" "-c"
         ;; Allow native build scripts (koffi, protobufjs, @google/genai need them).
         ;; pnpm 11 blocks these by default; dangerouslyAllowAllBuilds opts out.
         (string-append
          "export SHELL=$(command -v bash); "
          ;; Reuse the manifest's python instead of downloading a standalone one.
          "export UV_PYTHON_PREFERENCE=system; "
          "export PNPM_HOME=\"$HOME/.local/share/pnpm\"; "
          "export PATH=\"$PNPM_HOME/bin:$PNPM_HOME:$PATH\"; "
          "pnpm config set dangerouslyAllowAllBuilds true; "
          "pnpm remove -g @mariozechner/pi-coding-agent >/dev/null 2>&1 || true; "
          "pnpm add -g @earendil-works/pi-coding-agent@latest; "
          "exec pi \"$@\"")
         "pi-guix")
   pi-args))

(define (main)
  (call-with-values
    (lambda () (parse-args (cdr (command-line))))
    (lambda (mode manifest pi-args)
      (unless (file-exists? manifest)
        (format (current-error-port)
                "pi-guix: manifest not found: ~a~%" manifest)
        (exit 1))

      (format #t "pi-guix: mode: ~a~%" (mode-name mode))
      (format #t "pi-guix: using manifest: ~a~%" manifest)
      (unless (null? pi-args)
        (format #t "pi-guix: pi args: ~a~%" (string-join pi-args " ")))

      (run-guix "pi-guix" (guix-args mode manifest pi-args)))))

(main)
