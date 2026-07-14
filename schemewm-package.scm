;;; Select the normal schemewm checkout package or an explicit RC archive.
;;; The final expression is a package object for primitive-load callers.

(define checkout "/home/samuel/Projects/scheme-wayland-wm")
(define archive (getenv "SCHEMEWM_RC_ARCHIVE"))

(if (and archive (not (string-null? archive)))
    (let ((revision (getenv "SCHEMEWM_RC_REVISION")))
      (unless (file-exists? archive)
        (error "SCHEMEWM_RC_ARCHIVE does not exist" archive))
      (unless (and revision (not (string-null? revision)))
        (error "SCHEMEWM_RC_REVISION is required with SCHEMEWM_RC_ARCHIVE"))
      (setenv "SCHEMEWM_SOURCE_ARCHIVE" archive)
      (setenv "SCHEMEWM_VERSION" "1.0.0-rc1")
      (setenv "SCHEMEWM_BUILD_REVISION" revision)
      (primitive-load (string-append checkout "/guix/release.scm")))
    (primitive-load (string-append checkout "/guix.scm")))
