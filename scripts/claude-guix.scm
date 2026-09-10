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

(define home (require-home "claude-guix"))

(define default-manifest
  (string-append home "/Projects/System/home/manifests/claude.scm"))

(define (usage)
  (format #t "Usage: claude-guix [--full|--sandbox|--host] [PROJECT-DIR] [-m MANIFEST-PATH]... [-- CLAUDE-ARGS...]~%")
  (format #t "       claude-guix --resume SESSION-ID~%")
  (format #t "  Default mode: full. Pass --sandbox for a project-only Guix shell.~%")
  (format #t "  --host runs Claude in a plain guix shell (no container): full host~%")
  (format #t "     access incl. sudo, /sys, herd and guix generations.~%")
  (format #t "  PROJECT-DIR defaults to the current directory.~%")
  (format #t "  -m may be given multiple times; each manifest is layered~%")
  (format #t "     on top of the base manifest: ~a~%" default-manifest)
  (format #t "  Unknown options are passed to Claude. Use -- before Claude args when ambiguous.~%"))

(define (parse-args args)
  ;; extra-manifests accumulates user -m paths (in order); the base manifest
  ;; is always included so bash/node/npm/git are present in the profile.
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
      ((string=? (car rest) "--host")
       (loop (cdr rest) 'host project extra-manifests claude-args))
      ((and (string=? (car rest) "-m") (pair? (cdr rest)))
       (loop (cddr rest) mode project
             (cons (resolve-directory (expand-user-path home (cadr rest))) extra-manifests)
             claude-args))
      ((string-prefix? "-" (car rest))
       (values mode (or project (getcwd)) (reverse extra-manifests) rest))
      ((not project)
       (loop (cdr rest) mode (resolve-directory (expand-user-path home (car rest))) extra-manifests claude-args))
      (else
       (values mode project (reverse extra-manifests) rest)))))

(define (manifest-args manifests)
  (append-map (lambda (m) (list "-m" m)) manifests))

(define (guix-args mode extra-manifests project-dir claude-args)
  (ensure-directory (string-append home "/.claude"))
  (for-each (lambda (path) (ensure-directory (string-append home path)))
            '("/.cache" "/.cache/agent-npm" "/.local" "/.local/share"
              "/.local/share/agent-tools" "/.local/share/agent-tools/claude"))
  (let ((cmd (string-append
              "export SHELL=$(command -v bash); "
              ;; Reuse the manifest's python instead of letting uv download a
              ;; standalone CPython on first use.
              "export UV_PYTHON_PREFERENCE=system; "
              ;; Prefer the manifest's ripgrep over the vendored binary.
              "export USE_BUILTIN_RIPGREP=0; "
              ;; Keep the package's native executable separate from the public
              ;; ~/.local/bin/claude Guix launcher; never replace that launcher.
              "export CLAUDE_NPM_PREFIX=\"$HOME/.local/share/agent-tools/claude\"; "
              "export PATH=\"$CLAUDE_NPM_PREFIX/bin:$PATH\"; "
              "cd "
              (format #f "~s" project-dir)
              " && if [ ! -x \"$CLAUDE_NPM_PREFIX/bin/claude\" ]; then"
              " npm install --global --prefix \"$CLAUDE_NPM_PREFIX\""
              " --cache \"$HOME/.cache/agent-npm\""
              " @anthropic-ai/claude-code@latest; fi"
              ;; Register MCP servers (user scope -> ~/.claude.json, shared into
              ;; the container so it persists). Re-register each launch so the
              ;; baked --executable-path always tracks the current chromium store
              ;; path (it changes when the manifest/channels update). HEADED
              ;; (kein --headless): der Container erbt DISPLAY/WAYLAND_DISPLAY der
              ;; startenden Session, ein echter headed Browser umgeht Anti-Bot-
              ;; Erkennung, die HeadlessChrome hart blockt. Bei rein
              ;; headless/SSH ohne Display hier wieder --headless ergaenzen.
              ;; --user-data-dir = persistentes echtes Profil (Cookies/History).
              ;; Config wird von pw-mcp-gen-config.scm erzeugt (loest chromium-Pfad
              ;; auf, headed, und laedt die webgl-spoof-Extension via
              ;; launchOptions.args). Die Extension ueberschreibt den SwiftShader-
              ;; WebGL-Renderer, den Bot-Erkennung als Tell
              ;; fingerprinten. Fuer reinen SSH/headless-Lauf PW_MCP_HEADLESS=1.
              " && { \"$HOME/Projects/System/scripts/pw-mcp-gen-config.scm\";"
              " \"$CLAUDE_NPM_PREFIX/bin/claude\" mcp remove -s user playwright >/dev/null 2>&1;"
              " \"$CLAUDE_NPM_PREFIX/bin/claude\" mcp add -s user playwright --"
              " npx -y @playwright/mcp@latest"
              " --config \"$HOME/.cache/pw-mcp-config.json\" || true; }"
              " && exec \"$CLAUDE_NPM_PREFIX/bin/claude\" --dangerously-skip-permissions \"$@\"")))
    (append
     (if (eq? mode 'host)
         ;; Host mode: no container at all. The manifest only adds node/npm
         ;; and the agent tools to PATH; everything else (sudo, /sys, herd,
         ;; /var/guix/profiles, host processes) is the real system. Claude's
         ;; native binary needs /lib64/ld-linux-x86-64.so.2, which
         ;; systems/base-system.scm provides via extra-special-file (do not
         ;; patchelf the binary: Bun executables carry their payload at fixed
         ;; file offsets and segfault after patching).
         '("shell")
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
           (git-config-mounts home)
           ;; claude credentials and state (read-write)
           (list (string-append "--share=" home "/.claude=" home "/.claude"))
           (maybe-mount "--share"
                        (string-append home "/.claude.json")
                        (string-append home "/.claude.json"))
           ;; Persist the installed CLI and package downloads in sandbox mode.
           (list (string-append "--share=" home "/.cache/agent-npm=" home "/.cache/agent-npm"))
           (list (string-append "--share=" home "/.local/share/agent-tools/claude=" home "/.local/share/agent-tools/claude")))
          '())
      ;; Host Docker/Podman sockets for container-backed tools.
      (container-socket-mounts)
      ;; Removable media (e.g. /run/media/samuel/Seagate), read-write when present.
      (maybe-mount "--share"
                   (string-append "/run/media/" (env "USER" "samuel"))
                   (string-append "/run/media/" (env "USER" "samuel")))
      ;; GPU device nodes: gives the container real hardware-accelerated WebGL
      ;; instead of software SwiftShader. Software rendering is a strong anti-bot
      ;; signal -- a real GPU makes the automated browser's
      ;; canvas/GL behaviour match a normal desktop browser. Read-write (DRM
      ;; render nodes need it); only mounted when the host actually has a GPU.
      (maybe-mount "--share" "/dev/dri" "/dev/dri")
      ;; runtime / display
      (xdg-runtime-expose)
      (guix-profiles-expose)
      (preserve-common-env)))
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

      (run-guix "claude-guix" (guix-args mode extra-manifests project-dir claude-args)))))

(main)
