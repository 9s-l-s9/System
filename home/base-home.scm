;;; base-home.scm --- Shared home-environment building blocks
;;;
;;; Both per-user entry points (samuel, levi) compose their final
;;; `home-environment' on top of the helpers exported here:
;;;
;;;   - `base-services'  returns the services every user shares
;;;     (window manager, git, redshift, dotfiles tree).
;;;   - per-user files add their user-specific services on top.

(define-module (base-home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (services stumpwm)
  #:use-module (services git)
  #:use-module (services redshift)
  #:use-module (services agent-skills)
  #:export (base-services))

(define (base-services)
  "Services shared by every user's home environment."
  (list
   (stumpwm-service)
   (git-service)
   (redshift-service)
   (agent-skills-service)
   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files"))))))
