(define-module (manifests codex)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/uv/python/nss-certs/... — see agent-base.scm).
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

(specifications->manifest
 (append base-specs
         '("node@22"
           "curl"
           "bind:utils"   ; dig/nslookup for network debugging
           "poppler")))   ; pdftotext etc. for document handling
