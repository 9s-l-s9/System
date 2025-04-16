;; Home configuration for the user "levi"
;; This users home should only be configured for focused work tasks

(define-module (home-configuration)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (packages base-packages)
  #:use-module (services bash)
  #:use-module (services stumpwm)
  #:use-module (services lem)
  #:use-module (services git)
  #:use-module (services redshift))

(home-environment
 (specifications->packages
  (append
   xorg-packages
   "nyxt"
   utilities-packages))
 (services
  (list
   (bash-service)
   (stumpwm-service)
   (git-service)
   (redshift-service)   
   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files"))))
   )))

