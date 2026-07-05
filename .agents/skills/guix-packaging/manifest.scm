;; Layered manifest for the guix-packaging skill.
;;
;; The claude-guix launcher runs Claude inside `guix shell --container
;; --nesting`.  Nesting exposes the build daemon socket
;; (/var/guix/daemon-socket/socket) and the store read-only, but it does NOT
;; reliably put the `guix` command itself on PATH ("could not add current Guix
;; to the profile").  This manifest supplies the missing `guix` binary plus the
;; tools the packaging workflow needs (TLS certs for downloads, git for
;; git-fetch sources and channels).
;;
;; Usage:
;;   claude-guix -m .agents/skills/guix-packaging/manifest.scm

(use-modules (guix profiles))

(specifications->manifest
 '("guix"
   "nss-certs"
   "git"
   "coreutils"))
