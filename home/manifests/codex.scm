(use-modules (guix utils))

(eval-when (expand load eval)
  (add-to-load-path (dirname (current-source-directory))))

(define-module (manifests codex)
  #:use-module (gnu packages)
  #:use-module (manifests agent-base))

;; node comes from agent-base.scm now; codex uses npm, not pnpm.
(specifications->manifest
 (append agent-base-specs
         '("bind:utils"   ; dig/nslookup for network debugging
           "poppler")))   ; pdftotext etc. for document handling
