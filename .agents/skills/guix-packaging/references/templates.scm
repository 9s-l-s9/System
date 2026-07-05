;;; Ready-to-edit Guix package templates.
;;;
;;; Each block below is a STANDALONE package file: it loads the modules it uses
;;; and ends with a bare `(package ...)` so `guix build -f THIS-BLOCK.scm` works.
;;; Copy ONE block into its own file, edit the marked fields, then build.
;;; When moving a finished package into a module, wrap it in `define-public`.

;; ---------------------------------------------------------------------------
;; 1. FONT from a release archive (.zip / .tar.gz of .ttf/.otf files)
;;    The canonical case: Google Fonts, foundry releases, etc.
;; ---------------------------------------------------------------------------
;; (use-modules (guix packages)
;;              (guix download)
;;              (guix build-system font)
;;              ((guix licenses) #:prefix license:))
;;
;; (package
;;   (name "font-space-mono")                 ; convention: font-<family>
;;   (version "1.000")
;;   (source
;;    (origin
;;      (method url-fetch)
;;      (uri "https://github.com/googlefonts/spacemono/archive/refs/tags/v1.000.zip")
;;      (sha256
;;       (base32 "0000000000000000000000000000000000000000000000000000")))) ; guix download
;;   (build-system font-build-system)
;;   (home-page "https://fonts.google.com/specimen/Space+Mono")
;;   (synopsis "Fixed-width display typeface")
;;   (description "Space Mono is an original monospaced display typeface
;; designed by Colophon Foundry for Google Fonts.")
;;   (license license:silofl1.1))

;; ---------------------------------------------------------------------------
;; 2. FONT from a git tag (when there is no published archive)
;; ---------------------------------------------------------------------------
;; (use-modules (guix packages)
;;              (guix git-download)
;;              (guix build-system font)
;;              ((guix licenses) #:prefix license:))
;;
;; (define commit "v1.000")
;; (package
;;   (name "font-example")
;;   (version "1.000")
;;   (source
;;    (origin
;;      (method git-fetch)
;;      (uri (git-reference
;;            (url "https://github.com/owner/example-font")
;;            (commit commit)))
;;      (file-name (string-append "font-example-" version "-checkout"))
;;      (sha256
;;       (base32 "0000000000000000000000000000000000000000000000000000")))) ; guix hash -rx
;;   (build-system font-build-system)
;;   (home-page "https://example.com")
;;   (synopsis "Example typeface")
;;   (description "Example typeface packaged from a git tag.")
;;   (license license:silofl1.1))

;; ---------------------------------------------------------------------------
;; 3. PROGRAM from a release tarball (GNU autotools / CMake / Meson)
;; ---------------------------------------------------------------------------
;; (use-modules (guix packages)
;;              (guix download)
;;              (guix build-system gnu)        ; or (guix build-system cmake) / meson
;;              (gnu packages pkg-config)      ; example native input
;;              ((guix licenses) #:prefix license:))
;;
;; (package
;;   (name "hello-example")
;;   (version "1.2.3")
;;   (source
;;    (origin
;;      (method url-fetch)
;;      (uri (string-append "https://example.com/hello-" version ".tar.gz"))
;;      (sha256
;;       (base32 "0000000000000000000000000000000000000000000000000000"))))
;;   (build-system gnu-build-system)
;;   (native-inputs (list pkg-config))         ; build-time only
;;   (inputs (list))                           ; runtime libs go here
;;   (home-page "https://example.com")
;;   (synopsis "One-line summary, no trailing period, no \"A\"/\"The\"")
;;   (description "Full sentence(s) describing the program.")
;;   (license license:gpl3+))

;; ---------------------------------------------------------------------------
;; 4. SIMPLE = the runnable default below.
;;    Edit this one in place to test the workflow end to end.
;; ---------------------------------------------------------------------------
(use-modules (guix packages)
             (guix download)
             (guix build-system font)
             ((guix licenses) #:prefix license:))

(package
  (name "font-space-mono")
  (version "1.000")
  (source
   (origin
     (method url-fetch)
     (uri (string-append "https://github.com/googlefonts/spacemono/"
                         "archive/refs/tags/v" version ".zip"))
     ;; Replace with the real hash from: guix download <uri>
     (sha256
      (base32 "0000000000000000000000000000000000000000000000000000"))))
  (build-system font-build-system)
  (home-page "https://fonts.google.com/specimen/Space+Mono")
  (synopsis "Fixed-width display typeface")
  (description "Space Mono is an original fixed-width display typeface designed
by Colophon Foundry for Google Fonts.")
  (license license:silofl1.1))
