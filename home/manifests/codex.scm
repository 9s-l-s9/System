(define-module (manifests codex)
  #:use-module (gnu packages))

(specifications->manifest
   '("bash"
     "coreutils"
     "grep"
     "sed"
     "gawk"
     "git"
     "node"
     "nss-certs"
     "curl"
     "bind:utils"
     "docker-cli"
     "podman"
     "gh"
     "openssh"
     "guix"
     "guile"
     "make"
     "findutils"))
