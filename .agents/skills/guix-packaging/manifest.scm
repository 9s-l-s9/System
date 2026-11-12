(use-modules (guix utils))

;; Layer the shared Guix/git/certificate tools into either a host shell or
;; an explicitly selected --full/--sandbox container.
;; Usage: claude-guix --sandbox -m .agents/skills/guix-packaging/manifest.scm

(eval-when (expand load eval)
  (add-to-load-path
   (string-append (dirname (dirname (dirname (current-source-directory))))
                  "/home")))

(use-modules (guix profiles)
             (manifests agent-base))

(specifications->manifest agent-base-specs)
