;;; Shared by both systems and Guix Home. Installed Minde is a verified CI
;;; binary; local compilation requires an explicit MINDE_BUILD_LOCAL=1.
(add-to-load-path (string-append (dirname (current-filename)) "/scripts"))
(use-modules (lib minde-binary))

(define checkout "/home/samuel/Projects/minde")
(define archive (getenv "MINDE_RC_ARCHIVE"))
(define lock-file
  (string-append (dirname (current-filename)) "/minde-binary.lock.scm"))

(cond
 ;; Explicit development/release verification remains available.
 ((and archive (not (string-null? archive)))
  (let ((revision (getenv "MINDE_RC_REVISION")))
    (unless (file-exists? archive)
      (error "MINDE_RC_ARCHIVE does not exist" archive))
    (unless (and revision (not (string-null? revision)))
      (error "MINDE_RC_REVISION is required with MINDE_RC_ARCHIVE"))
    (setenv "MINDE_SOURCE_ARCHIVE" archive)
    (setenv "MINDE_VERSION" "1.0.0-rc1")
    (setenv "MINDE_BUILD_REVISION" revision)
    (primitive-load (string-append checkout "/guix/release.scm"))))
 ((equal? (getenv "MINDE_BUILD_LOCAL") "1")
  (primitive-load (string-append checkout "/guix.scm")))
 (else
  (unless (file-exists? lock-file)
    (error "No pinned Minde binary. Run make minde-install COMMIT=<full GitHub build commit> in System."))
  (prebuilt-minde-package (read-metadata lock-file))))
