(define-public emacs-typst-ts-mode
  (package
    (name "emacs-typst-ts-mode")
    (version "1.0") ; Adjust the version based on the commit or release you are packaging
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://git.sr.ht/~meow_king/typst-ts-mode")
                    ; Replace "commit-hash" with the actual commit hash you wish to use
                    (commit "commit-hash")))
              (file-name (string-append name "-" version "-checkout"))
              (sha256
               (base32 "0")))) ; Use the actual hash of the commit for verification
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs" ,emacs))) ; Ensure you have the correct version of Emacs as a dependency
    (home-page "https://git.sr.ht/~meow_king/typst-ts-mode")
    (synopsis "Typst mode for Emacs")
    (description "This package provides an Emacs mode for editing Typst files.")
    (license license:gpl3+))) ; Adjust the license according to the project's license
