(define-module (manifests claude)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/d2/uv/python/... — see agent-base.scm), loaded by
;; absolute path so no %load-path juggling is needed.
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

;; Claude's npm package supplies its native CLI (see claude-guix.scm).
;; Node/npm from agent-base also run the Playwright MCP server.
(specifications->manifest
 (append base-specs
         '(;; Browser for the Playwright MCP server. Playwright would otherwise
           ;; download its own Chromium, which can't launch in the FHS container
           ;; (missing libglib/nss/... closure); claude-guix.scm points the MCP
           ;; server at this one via --executable-path instead.
           "ungoogled-chromium")))
