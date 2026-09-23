(define-module (services fish)
  #:use-module (gnu services)
  #:use-module (gnu home services shells)
  #:use-module (guix gexp)
  #:export (fish-service))

;; Global (not universal) settings make the declared theme win over old
;; fish_config selections without writing mutable state at shell startup.
;; Konsole owns its palette in services/konsole.scm. Starship owns the prompt;
;; fish only styles command input, suggestions and the completion pager.
(define %fish-appearance
  (plain-file
   "fish-appearance.fish"
   "if status is-interactive
    set -g fish_greeting
    set -g fish_color_normal ebdbb2
    set -g fish_color_command b8bb26
    set -g fish_color_keyword fb4934
    set -g fish_color_quote fabd2f
    set -g fish_color_redirection 83a598
    set -g fish_color_end d3869b
    set -g fish_color_error fb4934
    set -g fish_color_param ebdbb2
    set -g fish_color_option ebdbb2
    set -g fish_color_comment a89984
    set -g fish_color_match --background=504945
    set -g fish_color_selection --background=504945
    set -g fish_color_search_match --background=504945
    set -g fish_color_history_current --bold
    set -g fish_color_operator 8ec07c
    set -g fish_color_escape d3869b
    set -g fish_color_autosuggestion 928374
    set -g fish_color_cwd fabd2f
    set -g fish_color_cwd_root fb4934
    set -g fish_color_user b8bb26
    set -g fish_color_host 83a598
    set -g fish_color_host_remote d3869b
    set -g fish_color_status fb4934
    set -g fish_color_cancel --reverse
    set -g fish_color_valid_path --underline
    set -g fish_pager_color_progress a89984
    set -g fish_pager_color_prefix fabd2f --bold
    set -g fish_pager_color_completion ebdbb2
    set -g fish_pager_color_description a89984
    set -g fish_pager_color_background normal
    set -g fish_pager_color_secondary_background normal
    set -g fish_pager_color_secondary_prefix fabd2f --bold
    set -g fish_pager_color_secondary_completion ebdbb2
    set -g fish_pager_color_secondary_description a89984
    set -g fish_pager_color_selected_background --background=504945
    set -g fish_pager_color_selected_prefix fabd2f --bold
    set -g fish_pager_color_selected_completion ebdbb2
    set -g fish_pager_color_selected_description ebdbb2

end
"))

(define (fish-service)
  (service home-fish-service-type
           (home-fish-configuration
            (environment-variables
             `(("GUILE_LOAD_PATH"
                . "$XDG_CONFIG_HOME/guix/current/share/guile/site/3.0:$HOME/.guix-home/profile/share/guile/site/3.0")
               ("GUILE_LOAD_COMPILED_PATH"
                . "$HOME/.guix-home/profile/lib/guile/3.0/site-ccache:$XDG_CONFIG_HOME/guix/current/lib/guile/3.0/site-ccache")
               ("GUIX_LOCPATH" . "$HOME_ENVIRONMENT/profile/lib/locales")))
            (aliases
             '(("ls" . "ls -p --color=auto")
               ("ll" . "ls -l")
               ("grep" . "grep --color=auto")
               ("gh" . "guix home reconfigure ~/Projects/System/home/samuel-home-configuration.scm")
               ("gs" . "sudo guix system reconfigure ~/Projects/System/systems/$(hostname).scm")
               ("reload-emacs" . "herd restart emacs-daemon")
               ;; Short names for the launcher executables that
               ;; agent-launchers installs into ~/.local/bin.
               ("codex" . "codex-guix")
               ("claude" . "claude-guix")
               ("claude-host" . "claude-guix --host")   ; no container: sudo, /sys, herd
               ("deepseek" . "dsh-guix")
               ("dsh" . "dsh-guix")
               ("drawio-render" . "~/.local/bin/drawio-render")
               ("drawio-export" . "~/.local/bin/drawio-render")
               ("opencode" . "opencode-guix")
               ("pi" . "pi-guix")
               ("alire-shell" . "guix shell --container --network --emulate-fhs git bash alire-bin curl coreutils nss-certs tar gzip --share=$HOME=$HOME")))
            (config (list %fish-appearance)))))
