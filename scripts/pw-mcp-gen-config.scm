#!/usr/bin/env -S guile -s
!#

;; Generates the @playwright/mcp config file used by claude-guix.scm.
;;
;; Why a config file instead of CLI flags: we need to pass Chromium args
;; (--load-extension for the WebGL-renderer spoof) which @playwright/mcp only
;; accepts via browser.launchOptions.args in a JSON config. The spoof extension
;; rewrites the SwiftShader WebGL renderer string that Cloudflare Turnstile /
;; Ashby fingerprint to block automated submits (see chromium-extensions/
;; webgl-spoof/). Headed by default (headless:false) so the container's Wayland/X
;; display is used; for a pure SSH/headless run set PW_MCP_HEADLESS=1.

(use-modules (ice-9 format)
             (srfi srfi-1))

(define (find-chromium)
  (let ((path (or (getenv "PATH") "")))
    (any (lambda (dir)
           (let ((candidate (string-append dir "/chromium")))
             (and (not (string-null? dir))
                  (access? candidate X_OK)
                  candidate)))
         (string-split path #\:))))

(define chromium (find-chromium))
(unless chromium
  (format (current-error-port) "pw-mcp-gen-config: chromium not found in PATH~%")
  (exit 1))

(define home (getenv "HOME"))
(define ext-dir (string-append home "/Projects/System/chromium-extensions/webgl-spoof"))
(define profile-dir (string-append home "/.cache/pw-mcp-profile"))
(define out (string-append home "/.cache/pw-mcp-config.json"))
(define headless (if (string=? (or (getenv "PW_MCP_HEADLESS") "0") "1") "true" "false"))

(define cache-dir (string-append home "/.cache"))
(unless (file-exists? cache-dir)
  (mkdir cache-dir))

(call-with-output-file out
  (lambda (port)
    (format port "{
  \"browser\": {
    \"browserName\": \"chromium\",
    \"userDataDir\": \"~a\",
    \"launchOptions\": {
      \"executablePath\": \"~a\",
      \"headless\": ~a,
      \"args\": [
        \"--no-sandbox\",
        \"--disable-extensions-except=~a\",
        \"--load-extension=~a\"
      ]
    }
  }
}
"
            profile-dir chromium headless ext-dir ext-dir)))

(format #t "pw-mcp-gen-config: wrote ~a (chromium=~a, headless=~a)~%"
        out chromium headless)
