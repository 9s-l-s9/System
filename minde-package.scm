;;; Select the normal minde checkout package or an explicit RC archive.
;;; The final expression is a package object for primitive-load callers.

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
