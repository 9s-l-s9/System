(define-module (samuel-home-configuration)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (packages base-packages)
  #:use-module (base-home)
  #:use-module (services fish)
  #:use-module (services helix)
  #:use-module (services lem))

(home-environment
 (packages (all-packages))
 (services
  (append (base-services)
          (list (fish-service)
                (helix-service)
                (lem-service)))))
