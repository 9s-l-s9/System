(use-modules (guix utils))

(eval-when (expand load eval)
  (add-to-load-path (dirname (current-source-directory))))

(define-module (manifests deepseek-harness)
  #:use-module (gnu packages)
  #:use-module (manifests agent-base))

;; Shared coding-agent tools plus the Node/pnpm runtime used by the official
;; @deepseek-ai/dsh package.
(specifications->manifest
 (append agent-base-specs
         ;; pnpm runs on Guix's Node 22 (from agent-base.scm).  dsh-guix
         ;; downloads the official prebuilt Node 24 runtime because this
         ;; channel has no substitute and would otherwise compile it locally.
         '("pnpm@9"
           "gcc-toolchain@14"
           "tar"
           "xz")))
