(define-module (packages emacs-typst-ts-mode)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs))

(define-public emacs-typst-ts-mode
  (package
    (name "emacs-typst-ts-mode")
    (version "1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.sr.ht/~meow_king/typst-ts-mode")
             (commit "commit-hash")))
       (file-name (string-append name "-" version "-checkout"))
       (sha256
        (base32 "0000000000000000000000000000000000000000000000000000"))))
    (build-system emacs-build-system)
    (propagated-inputs
     (list emacs))
    (home-page "https://git.sr.ht/~meow_king/typst-ts-mode")
    (synopsis "Typst mode for Emacs")
    (description "This package provides an Emacs mode for editing Typst files.")
    (license license:gpl3+)))
