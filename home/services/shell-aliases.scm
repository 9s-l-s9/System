(define-module (services shell-aliases)
  #:export (shell-aliases))

;; Shared by Bash and Fish. Bare agent names are executables installed by
;; services/agent-launchers.scm; gh belongs to the GitHub CLI.
(define shell-aliases
  '(("ls" . "ls -p --color=auto")
    ("ll" . "ls -l")
    ("grep" . "grep --color=auto")
    ("gs" . "make -C ~/Projects/System reconfigure-system")
    ("guh" . "make -C ~/Projects/System reconfigure-home")
    ("reload-emacs" . "herd restart emacs-daemon")
    ("claude-full" . "claude-guix --full")
    ("drawio-export" . "~/.local/bin/drawio-render")
    ("alire-shell" . "guix shell --container --network --emulate-fhs git bash alire-bin curl coreutils nss-certs tar gzip --share=\"$HOME=$HOME\"")))
