(define-module (packages valsi)
  #:declarative? #f
  #:use-module (guix packages)
  #:export (emacs-valsi))

;; Keep the package definition with its independently developed source tree.
;; This wrapper also contains the standalone file's `use-modules' side effects
;; inside the application-specific package module.
(define emacs-valsi
  (save-module-excursion
   (lambda ()
     (primitive-load "/home/samuel/Projects/valsi/valsi.scm"))))
