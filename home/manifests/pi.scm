(define-module (manifests pi)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/d2/uv/python/... — see agent-base.scm).
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

;; node/pnpm/ripgrep/fd all come from agent-base.scm now.
(specifications->manifest base-specs)
