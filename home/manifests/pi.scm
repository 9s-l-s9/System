(eval-when (expand load eval)
  (add-to-load-path "/home/samuel/Projects/System/home"))

(define-module (manifests pi)
  #:use-module (gnu packages)
  #:use-module (manifests agent-base))

;; Guix's Node 22 supplies the host-compatible loader/libraries. Pi requires
;; a newer Node: its launcher reuses the pinned runtime already used by dsh
;; and patches a private copy, leaving the shared download unchanged.
(specifications->manifest
 (append agent-base-specs '("tar" "xz" "patchelf")))
