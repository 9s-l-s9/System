(define-module (manifests codex)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/d2/uv/python/nss-certs/... — see agent-base.scm).
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

;; node comes from agent-base.scm now; codex uses npm, not pnpm.
(specifications->manifest
 (append base-specs
         '("bind:utils"   ; dig/nslookup for network debugging
           "poppler")))   ; pdftotext etc. for document handling
