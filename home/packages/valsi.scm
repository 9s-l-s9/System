(define-module (packages valsi)
  #:declarative? #f
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:export (emacs-valsi))

;; Keep the package definition with its independently developed source tree.
;; This wrapper also contains the standalone file's `use-modules' side effects
;; inside the application-specific package module.
(define emacs-valsi
  (save-module-excursion
   (lambda ()
     (let ((source (string-append
                    (dirname (dirname (dirname (current-source-directory))))
                    "/valsi/valsi.scm")))
       (unless (file-exists? source)
         (format (current-error-port) "ValSi: missing ~a; clone valsi beside System.~%" source)
         (error "ValSi recipe missing; clone valsi beside System" source))
       (primitive-load source)))))
