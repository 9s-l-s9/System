(use-modules (guix utils))

(eval-when (expand load eval)
  (add-to-load-path (dirname (current-source-directory))))

(define-module (manifests claude)
  #:use-module (gnu packages)
  #:use-module (manifests agent-base))

;; Claude's npm package supplies its native CLI (see claude-guix.scm).
;; Node/npm from agent-base also run the Playwright MCP server.
(specifications->manifest
 (append agent-base-specs
         '(;; Browser for the Playwright MCP server. Playwright would otherwise
           ;; download its own Chromium, which can't launch in the FHS container
           ;; (missing libglib/nss/... closure); claude-guix.scm points the MCP
           ;; server at this one via --executable-path instead.
           "guile-json"
           "ungoogled-chromium")))
