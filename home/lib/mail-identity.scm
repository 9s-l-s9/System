;;; mail-identity.scm --- Mailfence login and addresses, kept out of the repo
;;;
;;; The account name and addresses live in a private file next to the
;;; Mailfence password, so this public repository never names them:
;;;
;;;   ~/.local/share/mailfence/identity.scm   (mode 600)
;;;   ((user . "LOGIN")                        ; IMAP/SMTP/CalDAV login
;;;    (address . "me@example.org")            ; From address
;;;    (mailfence-address . "me@mailfence.com"))
;;;
;;; It is read when the home configuration is evaluated, so the values end
;;; up only in the local store.  Without the file (another machine, CI) the
;;; placeholders below are used and a warning is printed; the result builds
;;; but cannot log in.  scripts/mail-*.scm and the Emacs config read the
;;; same file at run time.

(define-module (lib mail-identity)
  #:export (mail-identity-file
            mail-identity))

(define mail-identity-file
  (string-append (or (getenv "HOME") "") "/.local/share/mailfence/identity.scm"))

(define %placeholders
  '((user . "mailfence-user")
    (address . "user@example.org")
    (mailfence-address . "user@mailfence.com")))

(define %identity
  (delay
    (if (file-exists? mail-identity-file)
        (call-with-input-file mail-identity-file read)
        (begin
          (format (current-error-port)
                  "warning: ~a missing; mail and calendar use placeholder accounts~%"
                  mail-identity-file)
          %placeholders))))

(define (mail-identity key)
  "The value for KEY ('user, 'address or 'mailfence-address)."
  (or (assq-ref (force %identity) key)
      (error "mail-identity: no entry in" mail-identity-file key)))
