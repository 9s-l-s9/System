(define-module (services git)
  #:use-module (gnu)
  #:use-module (lib identity)
  #:use-module (git-home-service)
  #:export (git-service))

(define (git-service)
  (service home-git-service-type
           (home-git-configuration
            (user.name user-name) ;; shared settings
            (user.email e-mail) ;; shared setting
            (extra-options
             '(
               ((filter "lfs") 
                (clean "git-lfs clean -- %f")
                (smudge "git-lfs smudge -- %f")
                (process "git-lfs filter-process")
                (required #t))
               
               (column
                (ui "auto"))
               
               (branch
                (sort "-committerdate"))
               
               (tag
                (sort "version:refname"))
               
               (init
                (defaultBranch "main"))
               
               (diff
                (algorithm "histogram")
                (colorMoved "plain")
                (mnemonicPrefix #t)
                (renames #t))

	       (core
		(sshCommand "ssh -i ~/.config/ssh/id_ed25519 -o UserKnownHostsFile=~/.config/ssh/known_hosts"))
		
               (push
                (default "simple")
                (autoSetupRemote #t)
                (followTags #t))
               
               (fetch
                (prune #t)
                (pruneTags #t)
                (all #t))
               )))))
