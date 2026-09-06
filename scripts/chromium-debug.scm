#!/usr/bin/env -S guile -s
!#

;; Startet Chromium mit offenem DevTools-Port + persistentem Profil, damit sich
;; der Playwright-MCP (--cdp-endpoint http://localhost:9222) andocken kann.
;; Siehe scripts/playwright-real-browser.org (Option B).

(use-modules (ice-9 format)
             (srfi srfi-1))

;; /bin/chromium only exists inside the FHS container; look up chromium on
;; PATH first (like pw-mcp-gen-config.scm does) so this also works on the host.
(define (find-chromium)
  (let ((path (or (getenv "PATH") "")))
    (any (lambda (dir)
           (let ((candidate (string-append dir "/chromium")))
             (and (not (string-null? dir))
                  (access? candidate X_OK)
                  candidate)))
         (string-split path #\:))))

(define chromium (or (find-chromium) "/bin/chromium"))

(define args (cdr (command-line)))
(define port (if (pair? args) (car args) "9222"))
(define profile
  (or (getenv "CHROMIUM_MCP_PROFILE")
      (string-append (getenv "HOME") "/.cache/chromium-mcp-profile")))

(unless (file-exists? profile)
  (system* "mkdir" "-p" profile))

(apply execlp chromium chromium
       (string-append "--remote-debugging-port=" port)
       (string-append "--user-data-dir=" profile)
       (if (pair? args) (cdr args) '()))
