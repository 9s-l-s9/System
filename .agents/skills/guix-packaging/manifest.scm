;; Layered manifest for the guix-packaging skill.
;;
;; The claude-guix launcher runs Claude inside `guix shell --container
;; --nesting`.  Nesting exposes the build daemon socket
;; (/var/guix/daemon-socket/socket) and the store read-only, but it does NOT
;; reliably put the `guix` command itself on PATH ("could not add current Guix
;; to the profile").  This manifest needs `guix` plus TLS certs for downloads
;; and git for git-fetch sources and channels -- all of which agent-base.scm
;; already provides, so this file is just that base with no extras.
;;
;; Usage:
;;   claude-guix -m .agents/skills/guix-packaging/manifest.scm

(eval-when (expand load eval)
  (add-to-load-path "/home/samuel/Projects/System/home"))

(use-modules (guix profiles)
             (manifests agent-base))

(specifications->manifest agent-base-specs)
