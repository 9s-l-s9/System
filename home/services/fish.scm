(define-module (services fish)
  #:use-module (gnu services)
  #:use-module (gnu home services shells)
  #:export (fish-service))

(define (fish-service)
  (service home-fish-service-type
           (home-fish-configuration
            (environment-variables
             `(("GUILE_LOAD_PATH"
                . "$XDG_CONFIG_HOME/guix/current/share/guile/site/3.0:$HOME/.guix-home/profile/share/guile/site/3.0")
               ("GUILE_LOAD_COMPILED_PATH"
                . "$HOME/.guix-home/profile/lib/guile/3.0/site-ccache:$XDG_CONFIG_HOME/guix/current/lib/guile/3.0/site-ccache")
               ("GUIX_LOCPATH" . "$HOME_ENVIRONMENT/profile/lib/locales")
               ("LD_LIBRARY_PATH" . "/usr/lib/cuda-11.2/lib64:$LD_LIBRARY_PATH")))
            (aliases
             '(("ls" . "ls -p --color=auto")
               ("ll" . "ls -l")
               ("grep" . "grep --color=auto")
               ("gh" . "guix home reconfigure ~/Projects/System/home/samuel-home-configuration.scm")
               ("gs" . "sudo guix system reconfigure ~/Projects/System/systems/$(hostname).scm")
               ("codex" . "~/Projects/System/scripts/codex-guix.scm")
               ("codex-full" . "~/Projects/System/scripts/codex-guix.scm --full")
               ("claude" . "~/Projects/System/scripts/claude-guix.scm")
               ("claude-full" . "~/Projects/System/scripts/claude-guix.scm --full")
               ("drawio-render" . "~/.local/bin/drawio-render")
               ("drawio-export" . "~/.local/bin/drawio-render")
               ("opencode" . "~/Projects/System/scripts/open-code-guix.scm")
               ("pi" . "~/Projects/System/scripts/pi-guix.scm")
               ("pi-full" . "~/Projects/System/scripts/pi-guix.scm --full")
               ("alire-shell" . "guix shell --container --network --emulate-fhs git bash alire-bin curl coreutils nss-certs tar gzip --share=$HOME=$HOME")))
            ;; You might want to add custom Fish config here
			    )))
