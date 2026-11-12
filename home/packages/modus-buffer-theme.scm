(define-module (packages modus-buffer-theme)
  #:declarative? #f
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:export (emacs-modus-buffer-theme))

;; Keep the package definition with its independently developed source tree.
;; That tree is a personal checkout, not part of this repo, so it is absent
;; on other machines. Guard the `load' so importing this module
;; never crashes `all-packages' there: fall back to #f, and have
;; base-packages.scm only add the package when it is not #f.
(define %source-file
  (string-append (dirname (dirname (dirname (current-source-directory))))
                 "/emacs-buffer-theme/guix.scm"))

(define emacs-modus-buffer-theme
  (and (file-exists? %source-file)
       (load %source-file)))
