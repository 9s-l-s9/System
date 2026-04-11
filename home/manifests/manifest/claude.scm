(define-module (manifests manifest claude)
  #:use-module (gnu packages)
  #:export (manifest-claude))

(define manifest-claude
  (specifications->manifest
   '("bash"
     "coreutils"
     "grep"
     "sed"
     "gawk"
     "git"
     "node"
     "pnpm"
     "gh"
     "openssh"
     "guix"
     "guile"
     "make"
     "findutils")))
