(define-module (manifests manifest.codex))

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
   "gh"
   "openssh"
   "guix"
   "guile"
   "make"
   "findutils"))
