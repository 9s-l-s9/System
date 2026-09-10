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
  (ensure-directory (string-append home "/.cache/agent-npm"))
  (ensure-directory (string-append home "/.pi"))
  (ensure-directory (string-append home "/.local"))
  (ensure-directory (string-append home "/.local/share"))
  (ensure-directory (string-append home "/.local/share/agent-tools"))
  (ensure-directory (string-append home "/.local/share/agent-tools/pi"))
  (ensure-directory (string-append home "/.local/share/dsh-node"))
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
        ;; Persistent npm prefix for Pi (including its installed package).
        (maybe-mount "--share"
                     (string-append home "/.cache/agent-npm")
                     (string-append home "/.cache/agent-npm"))
        (maybe-mount "--share"
                     (string-append home "/.local/share/agent-tools/pi")
                     (string-append home "/.local/share/agent-tools/pi"))
        ;; Persistent pinned Node runtime (Pi requires newer Node than Guix's).
        (maybe-mount "--share"
                     (string-append home "/.local/share/dsh-node")
                     (string-append home "/.local/share/dsh-node"))
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
         (string-append
          "set -e -o pipefail; "
          "export SHELL=$(command -v bash); "
          ;; Reuse the manifest's python instead of downloading a standalone one.
          "export UV_PYTHON_PREFERENCE=system; "
          ;; Keep Pi in a dedicated prefix so its wrapper cannot resolve back
          ;; to this launcher through the user's normal PATH.
          "export PI_PREFIX=\"$HOME/.local/share/agent-tools/pi\"; "
          ;; Pi requires Node >=22.19; reuse dsh's pinned Node 24 runtime.
          "NODE_VERSION=24.18.0; "
          "NODE_ROOT=\"$HOME/.local/share/dsh-node/node-v$NODE_VERSION-linux-x64\"; "
          "NODE_ARCHIVE=\"$HOME/.local/share/dsh-node/node-v$NODE_VERSION-linux-x64.tar.xz\"; "
          "RUNTIME_ROOT=\"$PI_PREFIX/runtime\"; "
          "RUNTIME_NODE=\"$RUNTIME_ROOT/bin/node\"; "
          "RUNTIME_MARKER=\"$RUNTIME_ROOT/node.marker\"; "
          "GUIX_NODE=\"$(command -v node)\"; "
          "GUIX_NODE_REAL=\"$(readlink -f \"$GUIX_NODE\")\"; "
          "GUIX_INTERP=\"$(patchelf --print-interpreter \"$GUIX_NODE\")\"; "
          "GUIX_RPATH=\"$(patchelf --print-rpath \"$GUIX_NODE\")\"; "
          "if [ ! -x \"$NODE_ROOT/bin/node\" ]; then "
          "curl -fL \"https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz\" "
          "-o \"$NODE_ARCHIVE\"; "
          "echo \"55aa7153f9d88f28d765fcdad5ae6945b5c0f98a36881703817e4c450fa76742  $NODE_ARCHIVE\" "
          "| sha256sum -c -; "
          "tar -xJf \"$NODE_ARCHIVE\" -C \"$HOME/.local/share/dsh-node\"; "
          "rm -f \"$NODE_ARCHIVE\"; fi; "
          "mkdir -p \"$RUNTIME_ROOT/bin\"; "
          "RUNTIME_SIGNATURE=\"interpreter-only-v1 $NODE_VERSION $GUIX_NODE_REAL\"; "
          "if [ ! -x \"$RUNTIME_NODE\" ] || [ \"$(cat \"$RUNTIME_MARKER\" 2>/dev/null || true)\" != \"$RUNTIME_SIGNATURE\" ]; then "
          "RUNTIME_TMP=\"$(mktemp \"$RUNTIME_ROOT/node.XXXXXX\")\"; "
          "RUNTIME_MARKER_TMP=\"$RUNTIME_TMP.marker\"; "
          "trap 'rm -f \"$RUNTIME_TMP\" \"$RUNTIME_MARKER_TMP\"' EXIT; "
          "cp \"$NODE_ROOT/bin/node\" \"$RUNTIME_TMP\"; "
          ;; Adding an RPATH to this upstream Node ELF crashes at startup.
          ;; Only change its interpreter; supply Guix libraries at execution.
          "patchelf --set-interpreter \"$GUIX_INTERP\" \"$RUNTIME_TMP\"; "
          "chmod +x \"$RUNTIME_TMP\"; "
          "mv -f \"$RUNTIME_TMP\" \"$RUNTIME_NODE\"; "
          "printf '%s' \"$RUNTIME_SIGNATURE\" > \"$RUNTIME_MARKER_TMP\"; "
          "mv -f \"$RUNTIME_MARKER_TMP\" \"$RUNTIME_MARKER\"; "
          "trap - EXIT; fi; "
          "export PATH=\"$RUNTIME_ROOT/bin:$NODE_ROOT/bin:$PI_PREFIX/bin:$PATH\"; "
          "export LD_LIBRARY_PATH=\"$GUIX_RPATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"; "
          ;; Use Pi's documented npm install command and refresh @latest each run.
          "npm install -g --prefix \"$PI_PREFIX\" --cache \"$HOME/.cache/agent-npm\""
          " --ignore-scripts @earendil-works/pi-coding-agent@latest"
          " || { [ -x \"$PI_PREFIX/bin/pi\" ] || exit 1;"
          " printf '%s\\n' 'pi-guix: update failed; starting installed Pi.' >&2; }; "
          "exec \"$PI_PREFIX/bin/pi\" \"$@\"")
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
