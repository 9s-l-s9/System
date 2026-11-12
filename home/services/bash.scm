(define-module (services bash)
  #:use-module (gnu services)
  #:use-module (gnu home services shells)
  #:use-module (services shell-aliases)
  #:export (bash-service))

(define (bash-service)
  (service home-bash-service-type
           (home-bash-configuration
            (environment-variables
             `(("GUILE_LOAD_PATH"
                . ,(string-join '("$XDG_CONFIG_HOME/guix/current/share/guile/site/3.0"
                                 "$HOME/.guix-home/profile/share/guile/site/3.0")
                               ":"))
               ("GUILE_LOAD_COMPILED_PATH"
                . ,(string-join '("$HOME/.guix-home/profile/lib/guile/3.0/site-ccache"
                                 "$XDG_CONFIG_HOME/guix/current/lib/guile/3.0/site-ccache")
                               ":"))
               ("GUIX_LOCPATH" . "$HOME_ENVIRONMENT/profile/lib/locales")))

            (aliases shell-aliases))))
