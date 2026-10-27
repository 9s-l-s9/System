(define-module (manifests antigravity)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/d2/uv/python/nss-certs/... — see agent-base.scm).
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

;; Antigravity CLI (agy) is a single native binary; the launcher fetches it
;; from Google's release manifest, so it only needs tar/gzip on top.
(specifications->manifest
 (append base-specs '("tar" "gzip")))
