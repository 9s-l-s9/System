(define-module (packages modus-buffer-theme)
  #:declarative? #f
  #:use-module (guix packages)
  #:export (emacs-modus-buffer-theme))

;; Keep the package definition with its independently developed source tree.
(define emacs-modus-buffer-theme
  (load "/home/samuel/Projects/emacs-buffer-theme/guix.scm"))
