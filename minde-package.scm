;;; Shared by both systems and Guix Home. Installed Minde is a verified CI
;;; binary; local compilation requires an explicit MINDE_BUILD_LOCAL=1.
(use-modules (guix utils))
(add-to-load-path (string-append (current-source-directory) "/scripts"))
(use-modules (lib minde-binary) (srfi srfi-1))

(define checkout
  (string-append (dirname (current-source-directory)) "/minde"))
(define archive (getenv "MINDE_RC_ARCHIVE"))
(define lock-file
  (string-append (current-source-directory) "/minde-binary.lock.scm"))

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
  (let ((metadata (read-metadata lock-file)))
    ;; Each machine imports the pinned build once. Do it here so a plain
    ;; reconfigure works after a lock bump; root evaluation (system
    ;; reconfigure) cannot run the user-side download, so make does it first.
    (unless (every (lambda (name) (file-exists? (assoc-ref metadata name)))
                   '(minde xwayland))
      (let ((importer (string-append (dirname lock-file) "/scripts/minde-binary.scm")))
        ;; Guix may load this file several times; attempt the import once.
        (unless (and (not (zero? (getuid)))
                     (not (getenv "MINDE_IMPORT_FAILED"))
                     (or (zero? (status:exit-val
                                 (system* "guix" "repl" "-q" "--" importer "ensure")))
                         (begin (setenv "MINDE_IMPORT_FAILED" "1") #f)))
          ;; Guix reports a failed module load only as an unbound variable,
          ;; so say what is actually missing before failing.
          (format (current-error-port)
                  "~%minde: pinned binary ~a is not imported and the automatic import failed.~%minde: run  make -C ~a minde-install  as your user.~%~%"
                  (assoc-ref metadata 'commit) (dirname lock-file))
          (error "Minde binary is not imported" (assoc-ref metadata 'minde)))))
    (prebuilt-minde-package metadata))))
