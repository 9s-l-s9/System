;; Home configuration for the user "levi"
;; This users home should only be configured for focused work tasks

(define-module (levi-home-configuration)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu packages)
  #:use-module (packages base-packages)
  #:use-module (base-home)
  #:use-module (services bash))

(home-environment
 (packages
  (specifications->packages
   (append xorg-packages
           utilities-packages)))
 (services
  (cons (bash-service) (base-services))))
