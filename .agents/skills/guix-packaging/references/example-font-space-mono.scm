(use-modules (guix packages)
             (guix git-download)
             (guix build-system font)
             ((guix licenses) #:prefix license:))

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
  (license license:silofl1.1))
