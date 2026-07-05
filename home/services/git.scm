(define-module (services git)
  #:use-module (gnu home services)
  #:use-module (gnu packages version-control)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:use-module (lib identity)
  #:export (git-service))

(define git-config-file
  (plain-file
   "gitconfig"
   (string-append
    "[user]\n"
    "\tname = " user-name "\n"
    "\temail = " e-mail "\n"
    "[filter \"lfs\"]\n"
    "\tclean = git-lfs clean -- %f\n"
    "\tsmudge = git-lfs smudge -- %f\n"
    "\tprocess = git-lfs filter-process\n"
    "\trequired = true\n"
    "[credential \"https://github.com\"]\n"
    "\thelper = !gh auth git-credential\n"
    "[column]\n"
    "\tui = auto\n"
    "[branch]\n"
    "\tsort = -committerdate\n"
    "[tag]\n"
    "\tsort = version:refname\n"
    "[init]\n"
    "\tdefaultBranch = main\n"
    "[diff]\n"
    "\talgorithm = histogram\n"
    "\tcolorMoved = plain\n"
    "\tmnemonicPrefix = true\n"
    "\trenames = true\n"
    "[core]\n"
    "\tsshCommand = ssh -i ~/.config/ssh/id_ed25519 -o UserKnownHostsFile=~/.config/ssh/known_hosts\n"
    "[push]\n"
    "\tdefault = simple\n"
    "\tautoSetupRemote = true\n"
    "\tfollowTags = true\n"
    "[fetch]\n"
    "\tprune = true\n"
    "\tpruneTags = true\n"
    "\tall = true\n")))

(define git-config-activation
  #~(begin
      (use-modules (guix build utils)
                   (srfi srfi-13))

      (define home (getenv "HOME"))
      (define xdg-config-home
        (or (getenv "XDG_CONFIG_HOME")
            (string-append home "/.config")))
      (define xdg-git-config
        (string-append xdg-config-home "/git/config"))
      (define global-git-config
        (string-append home "/.gitconfig"))

      (define (store-symlink? path)
        (let ((target (false-if-exception (readlink path))))
          (and target (string-prefix? "/gnu/store/" target))))

      ;; The old git-home-service installed .config/git/config as a store
      ;; symlink, which made `git config --global` and `gh auth setup-git` fail.
      (when (store-symlink? xdg-git-config)
        (delete-file xdg-git-config))

      (unless (file-exists? global-git-config)
        (copy-file #$git-config-file global-git-config)
        (chmod global-git-config #o644))))

(define (git-packages _config)
  (list git (list git "send-email")))

(define (git-activation _config)
  git-config-activation)

(define git-service-type
  (service-type
   (name 'mutable-git)
   (extensions
    (list
     (service-extension home-profile-service-type git-packages)
     (service-extension home-activation-service-type git-activation)))
   (default-value #f)
   (description "Install Git and seed a mutable global Git configuration.")))

(define (git-service)
  (service git-service-type))
