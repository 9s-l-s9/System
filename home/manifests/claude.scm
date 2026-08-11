(define-module (manifests claude)
  #:use-module (gnu packages))

;; Shared base (bash/git/guix/uv/python/... — see agent-base.scm), loaded by
;; absolute path so no %load-path juggling is needed.
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

(specifications->manifest
 (append base-specs
         ;; Claude ships as a Node CLI installed via pnpm (see claude-guix.scm).
         '("node@22"
           "pnpm@9")))
