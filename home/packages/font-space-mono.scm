(define-module (packages font-space-mono)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system font))

;; Space Mono is not in upstream Guix.  Packaged from the googlefonts git
;; repository because the project publishes no stable release archive; the only
;; tag is named after a commit hash, so we pin an explicit commit instead.
;; Built and verified with `guix build -f` (see .agents/skills/guix-packaging).
(define-public font-space-mono
  (package
    (name "font-space-mono")
    (version "1.0.0-1.329858c")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/googlefonts/spacemono")
             (commit "329858c2c4dbd3476f972a4ae00624b018cf4b81")))
       (file-name (string-append "font-space-mono-" version "-checkout"))
       (sha256
        (base32 "1mklddqxd77pv8jgz2hd6k6zfg863xaafng60l61yckp8gvsm1x8"))))
    (build-system font-build-system)
    (home-page "https://fonts.google.com/specimen/Space+Mono")
    (synopsis "Fixed-width display typeface")
    (description "Space Mono is an original monospaced display typeface family
designed by Colophon Foundry for Google Fonts.  It includes regular, italic,
bold, and bold-italic styles and supports Latin-based languages.")
    (license license:silofl1.1)))

;; Make `guix build/install -f this-file.scm` work directly.
font-space-mono
