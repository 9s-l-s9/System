(define-module (manifests pi)
  #:use-module (gnu packages))

(specifications->manifest
 '("bash"
   "coreutils"
   "grep"
   "sed"
   "gawk"
   "git"
   "node"
   "pnpm"
   "podman"
   "gh"
   "openssh"
   "guix"
   "guile"
   "make"
   "findutils"
   "ripgrep"   ; pi uses rg for file search (falls back to downloading a binary if absent)
   "fd"))      ; pi uses fd for file listing
