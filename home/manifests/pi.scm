(define-module (manifests pi)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/d2/uv/python/... — see agent-base.scm).
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

;; Guix's Node 22 supplies the host-compatible loader/libraries. Pi requires
;; a newer Node: its launcher reuses the pinned runtime already used by dsh
;; and patches a private copy, leaving the shared download unchanged.
(specifications->manifest
 (append base-specs '("tar" "xz" "patchelf")))
