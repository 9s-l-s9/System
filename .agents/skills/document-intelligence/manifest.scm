;; Layered manifest for the document-intelligence skill: agent-base.scm
;; (bash/coreutils/python/nss-certs/...) plus the extras Docling needs.

(eval-when (expand load eval)
  (add-to-load-path "/home/samuel/Projects/System/home"))

(use-modules (guix profiles)
             (manifests agent-base))

(specifications->manifest
 (append agent-base-specs
         '("glib"
           "libxcb"
           "mesa"
           "python-pip"
           "python-virtualenv")))
