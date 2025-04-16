(define-module (services bash)
  #:use-module (gnu services)
  #:use-module (gnu home services shells)
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
               ("GUIX_LOCPATH" . "$HOME_ENVIRONMENT/profile/lib/locales")
               ("LD_LIBRARY_PATH" . "/usr/lib/cuda-11.2/lib64:$LD_LIBRARY_PATH")))

            (aliases
             '(("ls" . "ls -p --color=auto")
               ("ll" . "ls -l")
               ("grep" . "grep --color=auto")
               ("gh" . "guix home reconfigure ~/Projects/System/home/home-configuration.scm")
               ("gs" . "sudo guix system reconfigure ~/Projects/System/systems/$(hostname).scm")
               ("alire-shell" . "guix shell --container --network --emulate-fhs git bash alire-bin curl coreutils nss-certs tar gzip --share=$HOME=$HOME"))))))
