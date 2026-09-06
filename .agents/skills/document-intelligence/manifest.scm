;; Layered manifest for the document-intelligence skill: agent-base.scm
;; (bash/coreutils/python/nss-certs/...) plus the extras Docling needs.

(use-modules (guix profiles))

(define base-specs
  (primitive-load
   "/home/samuel/Projects/System/home/manifests/agent-base.scm"))

(specifications->manifest
 (append base-specs
         '("glib"
           "libxcb"
           "mesa"
           "python-pip"
           "python-virtualenv")))
