(define-module (samuel-wsl2-home-configuration)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (packages base-packages)
  #:use-module (services fish)
  #:use-module (services starship)
  #:use-module (services helix)
  #:use-module (services codex)
  #:use-module (services git))
  ;; WSLg supplies graphical windows; this home starts no compositor.

(home-environment
 (packages (wsl2-packages))
 (services
  (list
   (fish-service)
   (starship-service)
   (helix-service)
   (git-service)
   (codex-service)
   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files")))))))
