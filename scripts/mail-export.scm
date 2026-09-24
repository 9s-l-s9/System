#!/usr/bin/env -S guile -s
!#
;;; mail-export --- write notmuch messages as plain-text files
;;;
;;; Runs as notmuch's post-new hook (see home/services/mail.scm).  For every
;;; message tagged `new' it writes
;;;
;;;   ~/Mail/text/<year>/<YYYY-MM-DD_HHMM>_<domain>_<sender>_<subject>.txt
;;;
;;; with a header block (From, To, Cc, Date, Subject, Message-ID,
;;; In-Reply-To, Thread, Folder, Attachments, Calendar events) followed by
;;; the plain-text body; HTML-only mail is rendered with w3m.  Attachments
;;; land in a directory named like the text file, minus ".txt".  Mail from
;;; Sent Items is prefixed "out_" and named after the first recipient;
;;; mail from the spam folder is prefixed "spam_".
;;; Drafts are not exported.  Re-exporting a message overwrites its file.
;;;
;;; Afterwards it tags by folder (inbox, sent, draft, spam) and drops `new'.
;;;
;;; Usage:
;;;   mail-export.scm              export tag:new (hook mode)
;;;   mail-export.scm QUERY...     re-export any notmuch query, e.g. '*'

(use-modules (ice-9 binary-ports)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 textual-ports)
             (json)
             (srfi srfi-1)
             (srfi srfi-13)
             (srfi srfi-26))

;; The hook may run under the C locale; mail text is UTF-8 regardless, and
;; regexps on non-ASCII text need a UTF-8 locale.
(fluid-set! %default-port-encoding "UTF-8")
(unless (string-contains-ci (or (false-if-exception (setlocale LC_ALL "")) "") "UTF-8")
  (false-if-exception (setlocale LC_ALL "C.UTF-8")))

(define text-root (string-append (getenv "HOME") "/Mail/text"))

;;; Processes

(define (command-output program . args)
  (let* ((port (apply open-pipe* OPEN_READ program args))
         (out (get-string-all port)))
    (close-pipe port)
    out))

(define (notmuch . args)
  (apply command-output "notmuch" args))

(define (notmuch-json subcommand . args)
  (json-string->scm (apply notmuch subcommand "--format=json" args)))

;;; JSON helpers (guile-json: objects are alists, arrays are vectors)

(define (ref obj key)
  (and (pair? obj)
       (let ((cell (assoc key obj)))
         (and cell (not (eq? (cdr cell) 'null)) (cdr cell)))))

(define (as-list v)
  (cond ((vector? v) (vector->list v))
        ((list? v) v)
        (else '())))

;;; Naming

;; Code points rather than literals: the file must read the same under any
;; locale.  ä ö ü ß Ä Ö Ü é è
(define transliterations
  `((#xe4 . "ae") (#xf6 . "oe") (#xfc . "ue") (#xdf . "ss")
    (#xc4 . "ae") (#xd6 . "oe") (#xdc . "ue") (#xe9 . "e") (#xe8 . "e")))

(define (slug s max-len)
  "Lowercase ASCII words joined by '-', at most MAX-LEN characters."
  (let* ((mapped (string-concatenate
                  (map (lambda (ch)
                         (let ((t (assv (char->integer ch) transliterations)))
                           (cond (t (cdr t))
                                 ((or (char-numeric? ch)
                                      (and (char-alphabetic? ch)
                                           (< (char->integer ch) 128)))
                                  (string (char-downcase ch)))
                                 (else " "))))
                       (string->list (or s "")))))
         (s (string-join (string-tokenize mapped char-set:letter+digit) "-"))
         (s (if (> (string-length s) max-len)
                (string-trim-right (substring s 0 max-len) #\-)
                s)))
    (if (string-null? s) "x" s)))

(define (strip-reply-prefixes subject)
  (let loop ((s (string-trim-both (or subject ""))))
    (let ((m (string-match "^(re|aw|fwd?|wg|antw)(\\[[0-9]+\\])?:[ \t]*" (string-downcase s))))
      (if m (loop (substring s (match:end m))) s))))

;; "Name <user@host>" or "user@host" -> (name . address)
(define (parse-address s)
  (let ((m (string-match "^(.*)<([^>]+)>" (or s ""))))
    (if m
        (cons (string-trim-both (match:substring m 1) (char-set #\space #\"))
              (string-trim-both (match:substring m 2)))
        (cons "" (string-trim-both (or s ""))))))

(define (first-address s)
  (parse-address (car (string-split (or s "") #\,))))

(define (address-domain addr)
  (let ((at (string-index addr #\@)))
    (if at (substring addr (+ at 1)) addr)))

(define (address-person pair)
  (let ((name (car pair)) (addr (cdr pair)))
    (if (string-null? name)
        (let ((at (string-index addr #\@)))
          (if at (substring addr 0 at) addr))
        name)))

;;; Raw headers not present in notmuch's JSON (In-Reply-To, References)

(define (raw-header msg-id name)
  (let* ((raw (notmuch "show" "--format=raw" (string-append "id:" msg-id)))
         (end (or (string-contains raw "\n\n") (string-length raw)))
         (head (regexp-substitute/global #f "\r?\n[ \t]+" (substring raw 0 end)
                                         'pre " " 'post))
         (m (regexp-exec (make-regexp (string-append "(^|\n)" name ":[ \t]*([^\n]*)")
                                      regexp/icase)
                         head)))
    (and m (string-trim-both (match:substring m 2)))))

;;; Body

(define (html->text html)
  (let ((tmp (string-append "/tmp/mail-export-" (number->string (getpid)) ".html")))
    (call-with-output-file tmp (lambda (p) (put-string p html)))
    (let ((out (command-output "w3m" "-dump" "-T" "text/html" "-O" "UTF-8"
                               "-cols" "100" tmp)))
      (delete-file tmp)
      out)))

(define (part-type part)
  (string-downcase (or (ref part "content-type") "")))

(define (attachment? part)
  (and (ref part "filename") #t))

(define (all-parts part)
  "PART and every nested part, depth first."
  (let ((content (ref part "content")))
    (cons part
          (if (vector? content)
              (append-map all-parts (vector->list content))
              '()))))

(define (render-body part)
  "Readable text of PART: prefer text/plain inside alternatives."
  (let ((type (part-type part))
        (content (ref part "content")))
    (cond
     ((attachment? part) "")
     ((string=? type "text/plain") (if (string? content) content ""))
     ((string=? type "text/html") (if (string? content) (html->text content) ""))
     ((string=? type "multipart/alternative")
      (let* ((kids (as-list content))
             (plain (find (lambda (p) (string=? (part-type p) "text/plain")) kids)))
        (render-body (or plain (if (null? kids) '() (last kids))))))
     ((vector? content)
      (string-join (remove string-null?
                           (map render-body (vector->list content)))
                   "\n"))
     (else ""))))

;;; Calendar invitations: pull the facts that matter into the header

(define (ics-field ics name)
  ;; Search from BEGIN:VEVENT so VTIMEZONE's DTSTART is skipped.
  (let* ((unfolded (regexp-substitute/global #f "\r?\n[ \t]" ics 'pre "" 'post))
         (unfolded (let ((i (string-contains unfolded "BEGIN:VEVENT")))
                     (if (and i (not (string=? name "METHOD")))
                         (substring unfolded i)
                         unfolded)))
         (m (string-match (string-append "(^|\n)" name "(;[^:\n]*)?:([^\r\n]*)")
                          unfolded)))
    (and m (string-append (match:substring m 3)
                          (let ((params (match:substring m 2)))
                            (if params (string-append "  [" (substring params 1) "]") ""))))))

(define (calendar-lines parts)
  (append-map
   (lambda (p)
     (let ((ics (ref p "content")))
       (if (and (string-prefix? "text/calendar" (part-type p)) (string? ics))
           (filter-map
            (lambda (field)
              (let ((v (ics-field ics field)))
                (and v (string-append "Calendar-" field ": " v))))
            '("METHOD" "SUMMARY" "DTSTART" "DTEND" "ORGANIZER" "LOCATION"))
           '())))
   parts))

;;; Export

(define (folder-of msg)
  (let ((files (as-list (ref msg "filename"))))
    (cond ((any (cut string-contains <> "/Sent Items/") files) 'sent)
          ((any (cut string-contains <> "/Drafts/") files) 'draft)
          ((any (cut string-contains <> "/Spam?/") files) 'spam)
          (else 'inbox))))

(define (target-path msg folder)
  (let* ((headers (ref msg "headers"))
         (ts (ref msg "timestamp"))
         (tm (localtime ts))
         (other (first-address (if (eq? folder 'sent)
                                   (ref headers "To")
                                   (ref headers "From"))))
         (base (string-append
                (case folder ((sent) "out_") ((spam) "spam_") (else ""))
                (strftime "%Y-%m-%d_%H%M" tm) "_"
                (slug (address-domain (cdr other)) 30) "_"
                (slug (address-person other) 30) "_"
                (slug (strip-reply-prefixes (ref headers "Subject")) 60))))
    (string-append text-root "/" (strftime "%Y" tm) "/" base)))

(define (existing-message-id file)
  (and (file-exists? file)
       (call-with-input-file file
         (lambda (p)
           (let loop ((line (read-line p)))
             (cond ((or (eof-object? line) (string-null? line)) #f)
                   ((string-prefix? "Message-ID: " line)
                    (substring line 12))
                   (else (loop (read-line p)))))))))

(define (unique-base base msg-id)
  "BASE, or BASE-2, BASE-3 ... if another message already owns the name."
  (let loop ((n 1))
    (let* ((candidate (if (= n 1) base (string-append base "-" (number->string n))))
           (owner (existing-message-id (string-append candidate ".txt"))))
      (if (or (not owner) (string=? owner msg-id))
          candidate
          (loop (+ n 1))))))

(define (save-attachments msg-id parts dir)
  (filter-map
   (lambda (p)
     (and (attachment? p)
          (let ((name (ref p "filename")))
            (mkdir-p dir)
            (let* ((port (open-pipe* OPEN_READ "notmuch" "show" "--format=raw"
                                     (string-append "--part=" (number->string (ref p "id")))
                                     (string-append "id:" msg-id)))
                   (data (get-bytevector-all port)))
              (close-pipe port)
              (call-with-output-file (string-append dir "/" (basename name))
                (lambda (out)
                  (unless (eof-object? data) (put-bytevector out data)))
                #:binary #t))
            name)))
   parts))

(define (mkdir-p dir)
  (unless (file-exists? dir)
    (mkdir-p (dirname dir))
    (mkdir dir)))

(define (export-message msg)
  (let* ((msg-id (ref msg "id"))
         (folder (folder-of msg)))
    (unless (eq? folder 'draft)
      (let* ((headers (ref msg "headers"))
             (body-parts (as-list (ref msg "body")))
             (parts (append-map all-parts body-parts))
             (base (unique-base (target-path msg folder) (string-append "<" msg-id ">")))
             (attachments (save-attachments msg-id parts base))
             (field (lambda (label value)
                      (if (and value (not (string-null? value)))
                          (string-append label ": " value "\n")
                          ""))))
        (mkdir-p (dirname base))
        (call-with-output-file (string-append base ".txt")
          (lambda (out)
            (put-string
             out
             (string-append
              (field "From" (ref headers "From"))
              (field "To" (ref headers "To"))
              (field "Cc" (ref headers "Cc"))
              (field "Date" (ref headers "Date"))
              (field "Subject" (ref headers "Subject"))
              (field "Message-ID" (string-append "<" msg-id ">"))
              (field "In-Reply-To" (raw-header msg-id "In-Reply-To"))
              (field "Thread" (string-trim-both
                               (notmuch "search" "--output=threads"
                                        (string-append "id:" msg-id))))
              (field "Folder" (symbol->string folder))
              (field "Attachments" (string-join attachments ", "))
              (string-join (calendar-lines parts) "\n" 'suffix)
              "\n"
              (string-trim-right
               (string-join (map render-body body-parts) "\n"))
              "\n"))))))))

(define (messages-of nodes)
  "Flatten notmuch's [[msg, [replies...]], ...] structure."
  (append-map (lambda (node)
                (let ((node (as-list node)))
                  (if (null? node)
                      '()
                      (append (if (pair? (car node)) (list (car node)) '())
                              (messages-of (cadr node))))))
              (as-list nodes)))

(define (export-query query)
  (for-each
   (lambda (thread)
     (for-each export-message (messages-of thread)))
   (as-list (notmuch-json "show" "--entire-thread=false" "--body=true"
                          "--include-html" query))))

(define (main args)
  (let ((queries (cdr args)))
    (if (null? queries)
        (begin
          (export-query "tag:new")
          (notmuch "tag" "+inbox" "--" "tag:new" "folder:INBOX")
          (notmuch "tag" "+sent" "--" "tag:new" "folder:\"Sent Items\"")
          (notmuch "tag" "+draft" "--" "tag:new" "folder:Drafts")
          (notmuch "tag" "+spam" "--" "tag:new" "folder:\"Spam?\"")
          (notmuch "tag" "-new" "--" "tag:new"))
        (export-query (string-join queries " ")))))

(main (command-line))
