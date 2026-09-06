(define-module (manifests claude)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/d2/uv/python/... — see agent-base.scm), loaded by
;; absolute path so no %load-path juggling is needed.
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

;; Claude ships as a Node CLI installed via pnpm (see claude-guix.scm); node/pnpm
;; come from agent-base.scm now.
(specifications->manifest
 (append base-specs
         '(;; Browser for the Playwright MCP server. Playwright would otherwise
           ;; download its own Chromium, which can't launch in the FHS container
           ;; (missing libglib/nss/... closure); claude-guix.scm points the MCP
           ;; server at this one via --executable-path instead.
           "ungoogled-chromium")))
