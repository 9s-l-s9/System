;;; typst-preview.scm --- Live Typst preview for Emacs
;;;
;;; typst-preview.el drives `tinymist preview' (tinymist-bin from the
;;; binary-guix channel) over a websocket: edits are sent before saving,
;;; and a click in the browser preview jumps to the source line.  See
;;; typst-conf.el for wiring.
;;;
;;; This package pins typst-preview.el directly because it is not available
;;; from the Guix channel used by this configuration.

(define-module (packages typst-preview)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system emacs)
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs-build)   ; compat
  #:use-module (gnu packages emacs-xyz))    ; websocket

(define-public emacs-typst-preview
  (package
    (name "emacs-typst-preview")
    ;; Pinned to typst-preview.el HEAD as of 2026-10-17.
    (version "1.0.0-1.f2903a1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/havarddj/typst-preview.el/archive/"
                    "f2903a1b98e13be7c927de835ae0d9159dd9fb9a.tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0b94gq7q3hn78rfjq8xrg1s3yfim8k6j0pxvl4hgwy2hhvy75w01"))))
    (build-system emacs-build-system)
    ;; Matches typst-preview.el Package-Requires (sans the Emacs version bound).
    (propagated-inputs
     (list emacs-websocket
           emacs-compat))
    (home-page "https://github.com/havarddj/typst-preview.el")
    (synopsis "Live preview of Typst documents in the browser")
    (description
     "typst-preview.el connects Emacs to the tinymist preview server.  The
browser preview follows unsaved edits, and clicking in the preview moves
point to the corresponding source position.")
    (license license:gpl3+)))
