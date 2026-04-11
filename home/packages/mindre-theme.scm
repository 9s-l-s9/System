(define-module (packages mindre-theme)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module (gnu packages emacs-xyz) ; for emacs package dependencies, if any
  #:use-module ((guix licenses) #:prefix license:))

(define-public emacs-mindre-theme
  (package
    (name "emacs-mindre-theme")
    (version "0.1.5") ; Replace with the actual version
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/erikbackman/mindre-theme")
                    (commit "fc9ab1ba03494f2fb8cb8dc4e2ba5120ae35eb31"))) ; Replace with the actual commit hash
              (file-name (git-file-name name version))
              (sha256 (base32 "0434lm8pg7xcixaxk22hgw68x5vpadvfzs8gw4mvl5zzrkyls27i")))) ; Replace with the actual SHA-256 hash
    (build-system emacs-build-system)
    (home-page "https://github.com/erikbackman/mindre-theme")
    (synopsis "A modern theme for Emacs")
    (description "Mindre is a modern theme for Emacs.")
    (license license:expat))) ; Specify the correct license
