(define-module (manifests codex)
  #:use-module (gnu packages))

(specifications->manifest
   '("bash"
     "coreutils"
     "grep"
     "sed"
     "gawk"
     "git"
     "node@22"
     "nss-certs"
     "curl"
     "bind:utils"
     "podman"
     "gh"
     "openssh"
     "guix"
     "guile"
     "make"
     "findutils"))
