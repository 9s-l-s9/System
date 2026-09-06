;;; minde-package.scm --- Load-bearing: primitive-loaded by
;;; systems/T450s.scm, systems/X1.scm, and home/services/minde.scm to obtain
;;; the minde package object. Do not rename or relocate without updating
;;; those three call sites.
;;;
;;; Select the normal minde checkout package or an explicit RC archive.
;;; The final expression is a package object for primitive-load callers.
;;;
;;; MINDE_RC_ARCHIVE: path to a pre-built minde release-candidate source
;;; archive (from minde's `guix/release.scm'). When set and non-empty, this
;;; file builds from that archive instead of the live checkout, and
;;; MINDE_RC_REVISION (a short identifier, e.g. a commit or RC tag) becomes
;;; required and is baked into MINDE_BUILD_REVISION so the resulting binary
;;; can report which RC it was built from. Leave both unset for normal
;;; development, which builds straight from the /home/samuel/Projects/minde
;;; checkout.

(define checkout "/home/samuel/Projects/minde")
(define archive (getenv "MINDE_RC_ARCHIVE"))

(if (and archive (not (string-null? archive)))
    (let ((revision (getenv "MINDE_RC_REVISION")))
      (unless (file-exists? archive)
        (error "MINDE_RC_ARCHIVE does not exist" archive))
      (unless (and revision (not (string-null? revision)))
        (error "MINDE_RC_REVISION is required with MINDE_RC_ARCHIVE"))
      (setenv "MINDE_SOURCE_ARCHIVE" archive)
      (setenv "MINDE_VERSION" "1.0.0-rc1")
      (setenv "MINDE_BUILD_REVISION" revision)
      (primitive-load (string-append checkout "/guix/release.scm")))
    (primitive-load (string-append checkout "/guix.scm")))
