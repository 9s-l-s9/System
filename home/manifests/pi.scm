(define-module (manifests pi)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/uv/python/... — see agent-base.scm).
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

(specifications->manifest
 (append base-specs
         '("node"
           "pnpm"
           "ripgrep"   ; pi uses rg for file search (else downloads a binary)
           "fd")))     ; pi uses fd for file listing
