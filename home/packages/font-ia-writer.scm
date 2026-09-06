(define-module (packages font-ia-writer)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system font))

;; The iA Writer typefaces are not in upstream Guix.  Packaged from the
;; iaolo/iA-fonts git repository, which publishes no releases or tags, so we
;; pin an explicit commit (same approach as font-space-mono).  Installs the
;; Mono, Duo, and Quattro families (static and variable cuts).
(define-public font-ia-writer
  (package
    (name "font-ia-writer")
    (version "2018-1.f32c04c")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/iaolo/iA-fonts")
             (commit "f32c04c3058a75d7ce28919ce70fe8800817491b")))
       (file-name (string-append "font-ia-writer-" version "-checkout"))
       (sha256
        (base32 "1xvm690kag687lq7brm07gxx5zq3i6mivj7kwyx362szf7k7lgfr"))))
    (build-system font-build-system)
    (home-page "https://github.com/iaolo/iA-fonts")
    (synopsis "iA Writer Mono, Duo, and Quattro typewriter typefaces")
    (description "The iA Writer typeface family, derived from IBM Plex Mono,
carries a typewriter voice with modern metrics.  Mono is fully monospaced,
Duo is half-duospaced (wide M and W), and Quattro relaxes more widths for
prose.  Static and variable cuts in regular, italic, and bold styles are
included.")
    (license license:silofl1.1)))

;; Make `guix build/install -f this-file.scm` work directly.
font-ia-writer
