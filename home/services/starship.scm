(define-module (services starship)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (starship-service))

;; Keep the theme as native TOML next to its service.  Guix Home installs it
;; as ~/.config/starship.toml; no preset download or mutable theme setup is
;; needed at login.  Use the same store-backed executable for installation
;; and fish initialization so the prompt does not depend on PATH ordering.
(define starship-config
  (local-file "starship.toml"))

(define starship-fish-init
  (mixed-text-file
   "starship-init.fish"
   "if status is-interactive\n    "
   (file-append starship "/bin/starship")
   " init fish | source\nend\n"))

(define starship-service-type
  (service-type
   (name 'starship)
   (extensions
    (list
     (service-extension home-profile-service-type
                        (lambda (_) (list starship)))
     (service-extension home-xdg-configuration-files-service-type
                        (lambda (_) `(("starship.toml" ,starship-config))))
     (service-extension home-fish-service-type
                        (lambda (_)
                          (home-fish-extension
                           (config (list starship-fish-init)))))))
   (default-value #f)
   (description "Install Starship with a declarative Gruvbox theme for fish.")))

(define (starship-service)
  (service starship-service-type))
