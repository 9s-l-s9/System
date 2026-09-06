(define-module (manifests deepseek-harness)
  #:use-module (gnu packages))

;; Shared coding-agent tools plus the Node/pnpm runtime used by the official
;; @deepseek-ai/dsh package.
(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

(specifications->manifest
 (append base-specs
         ;; pnpm runs on Guix's Node 22 (from agent-base.scm).  dsh-guix
         ;; downloads the official prebuilt Node 24 runtime because this
         ;; channel has no substitute and would otherwise compile it locally.
         '("gcc-toolchain@14"
           "tar"
           "xz")))
