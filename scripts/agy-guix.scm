#!/usr/bin/env -S guile -s
!#

(eval-when (expand load eval)
  (add-to-load-path
   (string-append (dirname (canonicalize-path (car (command-line)))) "/lib")))

(use-modules (agent-launch)
             (ice-9 format)
             (srfi srfi-1)
             (srfi srfi-13))

(define home (require-home "agy-guix"))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/antigravity.scm"))

(define (usage)
  (format #t "Usage: agy-guix [--full|--sandbox] [MANIFEST-PATH] [-- AGY-ARGS...]~%")
  (format #t "Default mode: full. Pass --sandbox for a contained Guix shell.~%")
  (format #t "Default manifest: ~a~%" default-manifest)
  (format #t "Unknown options are passed to agy. Use -- before agy args when ambiguous.~%"))

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

(define (guix-args mode manifest agy-args)
  (for-each (lambda (path) (ensure-directory (string-append home path)))
            '("/.gemini" "/.cache" "/.local" "/.local/share"
              "/.local/share/agent-tools" "/.local/share/agent-tools/antigravity"))
  (append
   (if (eq? mode 'sandbox)
       (append
        '("shell" "--container" "--emulate-fhs" "--nesting" "--network")
        (git-config-mounts home)
        ;; Antigravity auth, settings, conversations (~/.gemini/antigravity-cli etc.)
        (maybe-mount "--share"
                     (string-append home "/.gemini")
                     (string-append home "/.gemini"))
        ;; Persist the downloaded (self-updating) binary.
        (maybe-mount "--share"
                     (string-append home "/.local/share/agent-tools/antigravity")
                     (string-append home "/.local/share/agent-tools/antigravity"))
        ;; Host Docker/Podman sockets for container-backed tools.
        (container-socket-mounts)
        (xdg-runtime-expose)
        (guix-profiles-expose)
        (preserve-common-env))
       ;; Full mode: no container. The binary wants
       ;; /lib64/ld-linux-x86-64.so.2, which systems/base-system.scm
       ;; provides via extra-special-file.
       '("shell"))
   (list "-m" manifest)
   (list "--" "bash" "-c"
         (string-append
          "set -e -o pipefail; "
          "export SHELL=$(command -v bash); "
          ;; Reuse the manifest's python instead of downloading a standalone one.
          "export UV_PYTHON_PREFERENCE=system; "
          ;; Keep the real binary out of ~/.local/bin, where `agy' is this
          ;; launcher. Do not run `agy install': it edits shell rc files.
          "AGY_PREFIX=\"$HOME/.local/share/agent-tools/antigravity\"; "
          "AGY=\"$AGY_PREFIX/agy\"; "
          ;; First install only, mirroring antigravity.google/cli/install.sh
          ;; (manifest -> sha512-verified tarball); afterwards agy updates
          ;; itself in the background.
          "if [ ! -x \"$AGY\" ]; then "
          "M=$(curl -fsSL https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json); "
          "URL=$(printf '%s' \"$M\" | sed -n 's/.*\"url\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p'); "
          "SHA=$(printf '%s' \"$M\" | sed -n 's/.*\"sha512\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p'); "
          "T=$(mktemp -d); trap 'rm -rf \"$T\"' EXIT; "
          "curl -fL \"$URL\" -o \"$T/agy.tar.gz\"; "
          "echo \"$SHA  $T/agy.tar.gz\" | sha512sum -c -; "
          "tar -xzf \"$T/agy.tar.gz\" -C \"$T\" antigravity; "
          "install -m 755 \"$T/antigravity\" \"$AGY\"; "
          "rm -rf \"$T\"; trap - EXIT; fi; "
          "exec \"$AGY\" \"$@\"")
         "agy-guix")
   agy-args))

(define (main)
  (call-with-values
    (lambda () (parse-args (cdr (command-line))))
    (lambda (mode manifest agy-args)
      (unless (file-exists? manifest)
        (format (current-error-port)
                "agy-guix: manifest not found: ~a~%" manifest)
        (exit 1))

      (format #t "agy-guix: mode: ~a~%" (mode-name mode))
      (format #t "agy-guix: using manifest: ~a~%" manifest)
      (unless (null? agy-args)
        (format #t "agy-guix: agy args: ~a~%" (string-join agy-args " ")))

      (run-guix "agy-guix" (guix-args mode manifest agy-args)))))

(main)
