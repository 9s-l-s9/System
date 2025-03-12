(define-module (home-configuration)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (packages)
  #:use-module (services bash)
  #:use-module (services stumpwm)
  #:use-module (services lem)
  #:use-module (services git)
  #:use-module (services redshift))

(home-environment
 (packages (all-packages))
 (services
  (list
   (bash-service)
   (stumpwm-service)
   (lem-service)
   (git-service)
   (redshift-service)
   
   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files"))))
   )))
