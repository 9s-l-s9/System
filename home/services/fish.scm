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
               ("GUIX_LOCPATH" . "$HOME/.guix-home/profile/lib/locales")
               ("LD_LIBRARY_PATH" . "/usr/lib/cuda-11.2/lib64:$LD_LIBRARY_PATH")))

            (aliases
             '(("ls"   . "ls -p --color=auto")
               ("ll"   . "ls -l")
               ("grep" . "grep --color=auto")
               ("alire-shell" . "guix shell --container --network --emulate-fhs git bash alire-bin curl coreutils nss-certs tar gzip --share=$HOME=$HOME")))

            (extra-config
             (list
              "
# ── Guix system management ───────────────────────────────────────────────────

# gh — reconfigure Guix home for current user
function gh --description 'guix home reconfigure'
    guix home reconfigure \
        --load-path=~/Projects/System/home \
        ~/Projects/System/home/samuel-home-configuration.scm $argv
end

# gs — reconfigure Guix system for the current machine (resolved via hostname)
function gs --description 'guix system reconfigure (current host)'
    sudo guix system reconfigure \
        --load-path=~/Projects/System/systems \
        ~/Projects/System/systems/(hostname).scm $argv
end

# gp — pull all channels
abbr --add gp 'guix pull'

# gu — pull channels then reconfigure home (full update)
function gu --description 'guix pull + guix home reconfigure'
    guix pull && gh
end

# ── AI agent launchers ────────────────────────────────────────────────────────
# Each runs the matching *-guix.scm script inside a Guix container.
# An optional manifest path can be passed as the first argument.

function claude --description 'Claude Code agent (Guix container)'
    ~/Projects/System/scripts/claude-guix.scm $argv
end

function pi --description 'Pi coding agent (Guix container)'
    ~/Projects/System/scripts/pi-guix.scm $argv
end

function codex --description 'OpenAI Codex (Guix container)'
    ~/Projects/System/scripts/codex-guix.scm $argv
end

function opencode --description 'OpenCode agent (Guix container)'
    ~/Projects/System/scripts/open-code-guix.scm $argv
end
")))))
