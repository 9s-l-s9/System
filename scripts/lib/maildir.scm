(define-module (lib maildir)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (trashed-maildir-path))

(define (trashed-maildir-path path)
  "Move new mail to cur and add the sorted T flag, preserving other flags.
Files without a Maildir suffix (including standalone drafts) get :2,T."
  (let* ((name (basename path))
         (colon (string-rindex name #\:))
         (suffix (and colon (string-prefix? ":2," (substring name colon)) colon))
         (stem (if suffix (substring name 0 suffix) name))
         (flags (if suffix (substring name (+ suffix 3)) ""))
         (directory (dirname path)))
    (string-append
     (if (string=? (basename directory) "new")
         (string-append (dirname directory) "/cur")
         directory)
     "/" stem ":2,"
     (list->string (sort (delete-duplicates (cons #\T (string->list flags)))
                        char<?)))))
