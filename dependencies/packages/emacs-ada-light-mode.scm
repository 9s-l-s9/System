(define-module (emacs-ada-light-mode)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module (guix licenses)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages version-control))

(define-public emacs-ada-light-mode
  (package
    (name "emacs-ada-light-mode")
    (version "0.1")  ; Replace with the actual version
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
               (url "https://github.com/AdaCore/ada-light-mode.git")
               (commit "main")))  ; Adjust commit as necessary
        (file-name (git-file-name name version))
        (sha256 (base32 "1da9pfwbz6r6rkigh5ljn0phq7iw4p9awr5258ww2qrdng2dy680")))) ; Replace with actual hash
    (build-system emacs-build-system)
    (propagated-inputs
      (list emacs-compat))  ; Ensure compat is available
    (home-page "https://github.com/AdaCore/ada-light-mode")
    (synopsis "Lightweight Ada mode for Emacs")
    (description "ada-light-mode is a very light alternative to ada-mode. It provides syntax highlighting, comment handling, Imenu support, and integration with the Ada language server via Eglot.")
    (license gpl3+)))


emacs-ada-light-mode
