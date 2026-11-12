#!/usr/bin/env -S guile -s
!#

;; Generates the @playwright/mcp config file used by claude-guix.scm.
;;
;; Why a config file instead of CLI flags: we need to pass Chromium args
;; (--load-extension for the WebGL-renderer spoof) which @playwright/mcp only
;; accepts via browser.launchOptions.args in a JSON config. The spoof extension
;; rewrites the SwiftShader WebGL renderer string that bot-detection
;; services fingerprint (see chromium-extensions/webgl-spoof/). Headed by default (headless:false) so the container's Wayland/X
;; display is used; for a pure SSH/headless run set PW_MCP_HEADLESS=1.

(use-modules (ice-9 format) (ice-9 textual-ports) (json) (srfi srfi-1))

(define mcp-version "0.0.85")
(define home (getenv "HOME"))
(define chromium
  (or (search-path (string-split (or (getenv "PATH") "") #\:) "chromium")
      (error "pw-mcp-gen-config: chromium not found in PATH")))
(define ext-dir (string-append home "/Projects/System/chromium-extensions/webgl-spoof"))
(define out (string-append home "/.cache/pw-mcp-config.json"))
(define config
  `(("browser" . (("browserName" . "chromium")
                  ("userDataDir" . ,(string-append home "/.cache/pw-mcp-profile"))
                  ("launchOptions" .
                   (("executablePath" . ,(canonicalize-path chromium))
                    ("headless" . ,(equal? (getenv "PW_MCP_HEADLESS") "1"))
                    ("args" . ,(vector "--no-sandbox"
                                      (string-append "--disable-extensions-except=" ext-dir)
                                      (string-append "--load-extension=" ext-dir)))))))))

(define (read-json path)
  (and (file-exists? path) (call-with-input-file path json->scm)))

(define (run! . args)
  (unless (zero? (apply system* args)) (error "MCP registration failed" (car args))))

(define serialized-config (string-append (scm->json-string config) "\n"))
(unless (file-exists? (dirname out)) (mkdir (dirname out)))
;; Serialize concurrent launchers. The lock closes on exec so Claude cannot
;; retain it after startup. No CLI process runs when registration matches.
(let ((lock (open-file (string-append out ".lock") "a")))
  (fcntl (fileno lock) F_SETFD FD_CLOEXEC)
  (flock lock LOCK_EX)
  (unless (and (file-exists? out)
               (equal? serialized-config (call-with-input-file out get-string-all)))
    (let* ((port (mkstemp (string-append out ".XXXXXX")))
           (temporary (port-filename port)))
      (display serialized-config port)
      (close-port port)
      (rename-file temporary out))
    (format #t "pw-mcp-gen-config: updated ~a~%" out))
  (when (member "--register" (cdr (command-line)))
    (let* ((settings (read-json (string-append home "/.claude.json")))
           (server (assoc-ref (or (assoc-ref (or settings '()) "mcpServers") '())
                              "playwright"))
           (args (list "-y" (string-append "@playwright/mcp@" mcp-version)
                       "--config" out))
           (cli (string-append (or (getenv "CLAUDE_NPM_PREFIX")
                                  (string-append home "/.local/share/agent-tools/claude"))
                               "/bin/claude")))
      (unless (and server (equal? (assoc-ref server "command") "npx")
                   (equal? (assoc-ref server "args") (list->vector args)))
        (when server (run! cli "mcp" "remove" "-s" "user" "playwright"))
        (apply run! cli "mcp" "add" "-s" "user" "playwright" "--" "npx" args))))
  (close-port lock))
