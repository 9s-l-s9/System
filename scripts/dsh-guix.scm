#!/usr/bin/env -S guile -s
!#

(eval-when (expand load eval)
  (add-to-load-path
   (string-append (dirname (canonicalize-path (car (command-line)))) "/lib")))

(use-modules (agent-launch)
             (ice-9 format)
             (srfi srfi-13))

(define home (require-home "dsh-guix"))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/deepseek-harness.scm"))

(define (usage)
  (format #t "Usage: dsh-guix [--full|--sandbox] [-- DSH-ARGS...]~%")
  (format #t "Default mode: full. With no DSH-ARGS, launches `dsh web`.~%"))

(define (parse-args args)
  (let loop ((rest args) (mode 'full))
    (cond
     ((null? rest) (values mode '("web")))
     ((member (car rest) '("-h" "--help")) (usage) (exit 0))
     ((string=? (car rest) "--")
      (values mode (if (null? (cdr rest)) '("web") (cdr rest))))
     ((string=? (car rest) "--full") (loop (cdr rest) 'full))
     ((string=? (car rest) "--sandbox") (loop (cdr rest) 'sandbox))
     (else (values mode rest)))))

(define (guix-args mode dsh-args)
  (ensure-directory (string-append home "/.cache"))
  (ensure-directory (string-append home "/.local"))
  (ensure-directory (string-append home "/.local/share"))
  (ensure-directory (string-append home "/.cache/pnpm"))
  (ensure-directory (string-append home "/.local/share/pnpm"))
  (ensure-directory (string-append home "/.local/share/pnpm/bin"))
  (ensure-directory (string-append home "/.local/share/dsh-node"))
  (ensure-directory (string-append home "/.dsh"))
  (append
   (if (eq? mode 'sandbox)
       (append
        '("shell" "--container" "--emulate-fhs" "--nesting" "--network")
        (git-config-mounts home)
        (list (string-append "--share=" home "/.dsh=" home "/.dsh")
              (string-append "--share=" home "/.cache/pnpm=" home "/.cache/pnpm")
              (string-append "--share=" home "/.local/share/pnpm="
                             home "/.local/share/pnpm")
              (string-append "--share=" home "/.local/share/dsh-node="
                             home "/.local/share/dsh-node"))
        (xdg-runtime-expose)
        (guix-profiles-expose)
        (maybe-preserve "DBUS_SESSION_BUS_ADDRESS")
        (maybe-preserve "DISPLAY")
        (maybe-preserve "WAYLAND_DISPLAY")
        (maybe-preserve "XDG_RUNTIME_DIR")
        (maybe-preserve "XAUTHORITY"))
       (append
        '("shell" "--container" "--emulate-fhs" "--nesting" "--network")
        (list (string-append "--share=" home "=" home))
        (xdg-runtime-expose)
        (guix-profiles-expose)
        (maybe-preserve "DBUS_SESSION_BUS_ADDRESS")
        (maybe-preserve "DISPLAY")
        (maybe-preserve "WAYLAND_DISPLAY")
        (maybe-preserve "XDG_RUNTIME_DIR")
        (maybe-preserve "XAUTHORITY")))
   (list "-m" default-manifest
         "--" "bash" "-c"
         (string-append
          "set -e -o pipefail; "
          "export SHELL=$(command -v bash); "
          "export PNPM_HOME=\"$HOME/.local/share/pnpm\"; "
          "NODE_VERSION=24.18.0; "
          "NODE_ROOT=\"$HOME/.local/share/dsh-node/node-v$NODE_VERSION-linux-x64\"; "
          "NODE_ARCHIVE=\"$HOME/.local/share/dsh-node/node-v$NODE_VERSION-linux-x64.tar.xz\"; "
          "if [ ! -x \"$NODE_ROOT/bin/node\" ]; then "
          "curl -fL \"https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz\" "
          "-o \"$NODE_ARCHIVE\"; "
          "echo \"55aa7153f9d88f28d765fcdad5ae6945b5c0f98a36881703817e4c450fa76742  $NODE_ARCHIVE\" "
          "| sha256sum -c -; "
          "tar -xJf \"$NODE_ARCHIVE\" -C \"$HOME/.local/share/dsh-node\"; "
          "rm -f \"$NODE_ARCHIVE\"; fi; "
          "export PATH=\"$NODE_ROOT/bin:$PNPM_HOME/bin:$PNPM_HOME:$PATH\"; "
          "if [ ! -x \"$PNPM_HOME/dsh\" ]; then "
          "pnpm add -g @deepseek-ai/dsh@latest; fi; "
          "exec \"$PNPM_HOME/dsh\" \"$@\"")
         "dsh-guix")
   dsh-args))

(define (main)
  (unless (file-exists? default-manifest)
    (format (current-error-port)
            "dsh-guix: manifest not found: ~a~%" default-manifest)
    (exit 1))
  (call-with-values
      (lambda () (parse-args (cdr (command-line))))
    (lambda (mode dsh-args)
      (format #t "dsh-guix: mode: ~a~%"
              (mode-name mode))
      (format #t "dsh-guix: dsh args: ~a~%" (string-join dsh-args " "))
      (let ((args (guix-args mode dsh-args)))
        (maybe-dry-run args)
        (let ((status (apply system* "guix" args)))
          (exit (if (zero? status) 0 1)))))))

(main)
