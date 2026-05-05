(define-module (samuel-wsl2-home-configuration)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (packages base-packages)
  #:use-module (services fish)
  #:use-module (services helix)
  #:use-module (services git))
  ;; Omitted vs samuel-home-configuration.scm:
  ;;   stumpwm — window manager; WSL2 has no bare X session to manage
  ;;   redshift — X11 blue-light filter; not applicable on WSL2

(home-environment
 (packages (wsl2-packages))
 (services
  (list
   (fish-service)
   (helix-service)
   (git-service)
   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files")))))))
