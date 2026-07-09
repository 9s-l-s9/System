(define-module (manifests claude)
  #:use-module (gnu packages))

(specifications->manifest
 '("bash"
   "coreutils"
   "grep"
   "sed"
   "gawk"
   "git"
   "node@22"
   "pnpm@9"
   "podman"
   "gh"
   "openssh"
   "guix"
   "guile"
   "make"
   "findutils"))
