#!/usr/bin/env -S guile -s
!#
;;; mail-unspam --- move one mail from Mailfence's spam folder to INBOX
;;;
;;; Mailfence files a lot of real job mail as spam and empties that folder
;;; after 30 days.  The local mirror keeps everything (channel mailfence-read
;;; is pull-only, Expunge None), but in the web UI and the apps the mail is
;;; gone.  This moves a mail on the server with IMAP UID MOVE, the only
;;; server write besides Drafts and Sent Items.  The next mbsync run pulls
;;; it into INBOX; the text export then writes it a second time without the
;;; spam_ prefix.
;;;
;;; MAIL is a Message-ID (with or without <>) or a mail file: a text export
;;; from ~/Mail/text or a Maildir file.  Only "Spam?" -> INBOX, nothing else.
;;;
;;; Safety:
;;;   - Refuses if the Message-ID is not in the spam folder (nothing moved).
;;;   - Checks afterwards that INBOX has the Message-ID.
;;;   - The password goes to curl in a mode-600 file that is removed again,
;;;     never on the command line.
;;;
;;; Usage: mail-unspam.scm MAIL

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 textual-ports)
             (srfi srfi-13))

(define imap-url "imaps://imap.mailfence.com/")
(define imap-user "samuelschmidt")
(define spam-folder "Spam%3F")               ; "Spam?" URL-encoded
(define password-file
  (string-append (getenv "HOME") "/.local/share/mailfence/password"))

(define (die fmt . args)
  (apply format (current-error-port) (string-append "mail-unspam: " fmt "~%") args)
  (exit 1))

(define (message-id-of arg)
  (cond
   ((file-exists? arg)
    (let* ((text (call-with-input-file arg get-string-all #:encoding "ISO-8859-1"))
           (m (string-match "(^|\n)[Mm]essage-[Ii][Dd]:[ \t]*\n?[ \t]*(<[^>\n]+>)" text)))
      (if m (match:substring m 2) (die "no Message-ID header in ~a" arg))))
   ((string-prefix? "<" arg) arg)
   (else (string-append "<" arg ">"))))

;; Runs one IMAP command on FOLDER and returns curl's output.
(define (imap folder command)
  (let* ((dir (or (getenv "XDG_RUNTIME_DIR") "/tmp"))
         (cfg (string-append dir "/mail-unspam-" (number->string (getpid)) ".curlrc"))
         (pw (string-trim-right (call-with-input-file password-file get-string-all))))
    (umask #o077)
    (call-with-output-file cfg
      (lambda (p) (format p "user = \"~a:~a\"~%" imap-user pw)))
    (let* ((port (open-pipe* OPEN_READ "curl" "-s" "-S" "--max-time" "60" "-K" cfg
                             "--url" (string-append imap-url folder) "-X" command))
           (out (get-string-all port))
           (status (close-pipe port)))
      (delete-file cfg)
      (unless (zero? (status:exit-val status))
        (die "curl failed (~a) on: ~a" (status:exit-val status) command))
      out)))

(define (uids-of search-output)
  (let ((m (string-match "\\* SEARCH([ 0-9]*)" search-output)))
    (if m (string-tokenize (match:substring m 1)) '())))

(define (search folder mid)
  (uids-of (imap folder (format #f "UID SEARCH HEADER Message-ID \"~a\"" mid))))

(define (main args)
  (unless (= (length args) 2)
    (die "usage: mail-unspam.scm MAIL (Message-ID or mail file)"))
  (let* ((mid (message-id-of (cadr args)))
         (uids (search spam-folder mid)))
    (when (null? uids)
      (die "~a is not in the spam folder (already moved?); nothing done" mid))
    (imap spam-folder (format #f "UID MOVE ~a INBOX" (string-join uids ",")))
    (if (null? (search "INBOX" mid))
        (die "moved ~a, but INBOX does not show it yet; check the web UI" mid)
        (format #t "moved to INBOX: ~a~%" mid))
    (system* "herd" "trigger" "mail-sync")))

(main (command-line))
