(eval-when (expand load eval)
  (add-to-load-path "/home/samuel/Projects/System/home"))

(define-module (manifests antigravity)
  #:use-module (gnu packages)
  #:use-module (manifests agent-base))

;; Antigravity CLI (agy) is a single native binary; the launcher fetches it
;; from Google's release manifest, so it only needs tar/gzip on top.
(specifications->manifest
 (append agent-base-specs '("tar" "gzip")))
