(define-module (samuel-home-configuration)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (packages base-packages)
  #:use-module (base-home)
  #:use-module (services fish)
  #:use-module (services helix)
  #:use-module (services lem))

(define emacs-naur
  ;; Load NAUR, whose output exposes its pinned Pi runtime as `pi'.  Keeping
  ;; this Samuel-specific avoids imposing /home/samuel on the shared desktop
  ;; and WSL package assemblers.
  (primitive-load "/home/samuel/Projects/naur/naur.scm"))

(home-environment
 (packages (cons emacs-naur (all-packages)))
 (services
  (append (base-services)
          (list (fish-service)
                (helix-service)
                (lem-service)))))
