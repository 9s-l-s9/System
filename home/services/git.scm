(define-module (services git)
  #:use-module (gnu home services)
  #:use-module (gnu packages base)
  #:use-module (gnu packages version-control)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:use-module (lib identity)
  #:export (git-service))

;; Global commit-msg hook: refuse any commit message that credits an AI
;; (Co-Authored-By trailers from Claude Code, its "Generated with" line,
;; Claude-Session trailers).  The Claude Code side is switched off in
;; services/claude.scm; this hook is the backstop for anything else.
;;
;; core.hooksPath replaces a repository's own .git/hooks, so the hook
;; chains to that directory's commit-msg when one exists.
(define commit-msg-hook
  (computed-file
   "commit-msg"
   #~(begin
       (call-with-output-file #$output
         (lambda (port)
           (display
            (string-append
             "#!/bin/sh\n"
             "# Installed by services/git.scm (guix home).\n"
             "if " #$(file-append grep "/bin/grep")
             " -qiE '^Co-Authored-By:.*(claude|anthropic)"
             "|^Claude-Session:|Generated with \\[?Claude' \"$1\"; then\n"
             "    echo 'commit-msg: AI attribution is not allowed in commit"
             " messages' >&2\n"
             "    exit 1\n"
             "fi\n"
             "repo_hook=\"$(" #$(file-append git "/bin/git")
             " rev-parse --git-dir)/hooks/commit-msg\"\n"
             "[ -x \"$repo_hook\" ] && exec \"$repo_hook\" \"$@\"\n"
             "exit 0\n")
            port)))
       (chmod #$output #o555))))

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
    "\thooksPath = ~/.config/git/hooks\n"
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
      (use-modules (srfi srfi-13))

      (let* ((home (getenv "HOME"))
             (xdg-config-home
              (or (getenv "XDG_CONFIG_HOME")
                  (string-append home "/.config")))
             (xdg-git-config
              (string-append xdg-config-home "/git/config"))
             (global-git-config
              (string-append home "/.gitconfig")))
        (define (store-symlink? path)
          (let ((target (false-if-exception (readlink path))))
            (and target (string-prefix? "/gnu/store/" target))))

        ;; The old git-home-service installed .config/git/config as a store
        ;; symlink, which made `git config --global` and `gh auth setup-git` fail.
        (when (store-symlink? xdg-git-config)
          (delete-file xdg-git-config))

        (unless (file-exists? global-git-config)
          (copy-file #$git-config-file global-git-config)
          (chmod global-git-config #o644))

        ;; The template above is only seeded once, so a ~/.gitconfig that
        ;; predates the hook needs the pointer added in place.  Idempotent.
        (system* #$(file-append git "/bin/git") "config" "--global"
                 "core.hooksPath" "~/.config/git/hooks"))))

(define (git-packages _config)
  (list git (list git "send-email")))

(define (git-activation _config)
  git-config-activation)

(define (git-xdg-files _config)
  `(("git/hooks/commit-msg" ,commit-msg-hook)))

(define git-service-type
  (service-type
   (name 'mutable-git)
   (extensions
    (list
     (service-extension home-profile-service-type git-packages)
     (service-extension home-activation-service-type git-activation)
     (service-extension home-xdg-configuration-files-service-type
                        git-xdg-files)))
   (default-value #f)
   (description "Install Git and seed a mutable global Git configuration.")))

(define (git-service)
  (service git-service-type))
