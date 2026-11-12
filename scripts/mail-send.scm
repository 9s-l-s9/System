#!/usr/bin/env -S guile -s
!#
;;; mail-send --- send one Mailfence draft over SMTP and file it in Sent Items
;;;
;;; Mailfence does not keep a copy of mail sent over SMTP, so this does what
;;; a mail client's Fcc does: msmtp sends the draft, the same message goes
;;; into the local Sent Items folder (flag S), and mbsync uploads it
;;; (channel mailfence-sent, Sync Pull PushNew).  In-Reply-To and References
;;; stay as they are in the draft, unlike a send from the Mailfence app.
;;;
;;; DRAFT is a Message-ID (with or without <>) or a file in Drafts/.
;;; Without --confirm it only syncs the drafts and shows what it would send.
;;;
;;; Safety:
;;;   - Drafts are synced first, so edits made in the app are sent.
;;;   - Refuses if the Message-ID is already in Sent Items (no double send).
;;;   - Never retries.  After an SMTP error it keeps the draft and says so;
;;;     an error after the data phase can still mean the mail went out.
;;;   - After a successful send the draft is flagged trashed, so the drafts
;;;     channel deletes it on the server and a second run finds nothing.
;;;   - If the upload fails, the copy stays local and the next timer sync
;;;     uploads it.
;;;
;;; Usage: mail-send.scm [--confirm] DRAFT

(add-to-load-path (dirname (or (current-filename) "scripts/mail-send.scm")))
(use-modules (lib maildir)
             (ice-9 ftw)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 textual-ports)
             (srfi srfi-1)
             (srfi srfi-13))

;; Latin-1 keeps every byte as one char, so the message goes out unchanged.
(define (read-bytes-as-string file)
  (call-with-input-file file get-string-all #:encoding "ISO-8859-1"))
(define (write-bytes-string file s)
  (call-with-output-file file (lambda (p) (put-string p s)) #:encoding "ISO-8859-1"))

(define mail-dir (string-append (getenv "HOME") "/Mail/mailfence"))
(define drafts-dir (string-append mail-dir "/Drafts"))
(define sent-dir (string-append mail-dir "/Sent Items"))
;; mbsync's MaxSize; a bigger message would never be uploaded.
(define max-size (* 20 1024 1024))

(define (die fmt . args)
  (apply format (current-error-port) (string-append "mail-send: " fmt "~%") args)
  (exit 1))

(define (maildir-files dir)
  (append-map (lambda (sub)
                (let ((d (string-append dir "/" sub)))
                  (map (lambda (f) (string-append d "/" f))
                       (or (scandir d (lambda (f) (not (string-prefix? "." f)))) '()))))
              '("cur" "new")))

(define (head-of msg)
  (let ((end (or (string-contains msg "\n\n") (string-length msg))))
    (substring msg 0 end)))

(define (header msg name)
  "First header NAME of MSG, unfolded, or #f."
  (let ((m (string-match (string-append "(^|\n)" name ":[ \t]*([^\n]*(\n[ \t][^\n]*)*)")
                         (head-of msg))))
    (and m (regexp-substitute/global #f "\n[ \t]+" (match:substring m 2) 'pre " " 'post))))

(define (bare-id id) (string-trim-both id (char-set #\< #\> #\space)))

(define (message-id-of file)
  (let ((v (header (read-bytes-as-string file) "Message-I[Dd]")))
    (and v (bare-id v))))

(define (find-draft arg)
  (if (string-index arg #\/)
      (if (file-exists? arg) arg (die "~a not found" arg))
      (let ((hits (filter (lambda (f) (equal? (message-id-of f) (bare-id arg)))
                          (maildir-files drafts-dir))))
        (cond ((null? hits) (die "no draft with Message-ID <~a>" (bare-id arg)))
              ((> (length hits) 1) (die "~a drafts share <~a>; pass the file" (length hits) (bare-id arg)))
              (else (car hits))))))

(define (rfc2822-date)
  (setlocale LC_TIME "C")
  (strftime "%a, %d %b %Y %H:%M:%S %z" (localtime (current-time))))

(define (set-date msg)
  (let ((head (head-of msg)) (rest (substring msg (string-length (head-of msg)))))
    (string-append
     (if (string-match "(^|\n)Date:" head)
         (regexp-substitute #f (string-match "(^|\n)Date:[^\n]*" head)
                            'pre 1 "Date: " (rfc2822-date) 'post)
         (string-append "Date: " (rfc2822-date) "\n" head))
     rest)))

(define (unique-name)
  (format #f "~a.~a_~a.~a" (current-time) (getpid) (random 1000000 (random-state-from-platform))
          (gethostname)))

(define (sync . channels)
  (zero? (apply system* "mbsync" channels)))

(define (after-send description thunk)
  "Run one follow-up without obscuring a successful SMTP delivery."
  (catch #t
    (lambda () (thunk) #t)
    (lambda (key . args)
      (format (current-error-port)
              "Gesendet, aber ~a fehlgeschlagen: ~s ~s. Nicht erneut senden.~%"
              description key args)
      #f)))

(define (checked-command . args)
  (let ((status (apply system* args)))
    (unless (zero? status) (error "command failed" args status))))

(define (main args)
  (let* ((confirm? (member "--confirm" args))
         (rest (remove (lambda (a) (string-prefix? "--" a)) (cdr args))))
    (unless (= (length rest) 1) (die "usage: mail-send.scm [--confirm] DRAFT"))
    (unless (sync "mailfence-drafts")
      (die "draft sync failed; not sending an outdated draft"))
    (let* ((draft (find-draft (car rest)))
           (msg (read-bytes-as-string draft))
           (id (or (message-id-of draft) (die "draft has no Message-ID")))
           (to (or (header msg "To") (die "draft has no To:"))))
      (when (any (lambda (f) (equal? (message-id-of f) id)) (maildir-files sent-dir))
        (die "<~a> is already in Sent Items; not sending again" id))
      (when (> (string-length msg) max-size)
        (die "draft is over 20 MB; mbsync would not upload the Sent copy"))
      (format #t "Entwurf: ~a~%Message-ID: <~a>~%To: ~a~%" draft id to)
      (for-each (lambda (h) (let ((v (header msg h))) (when v (format #t "~a: ~a~%" h v))))
                '("Cc" "Bcc" "Subject" "In-Reply-To"))
      (format #t "Größe: ~a kB~%" (quotient (string-length msg) 1024))
      (unless confirm?
        (format #t "Nicht gesendet (ohne --confirm).~%")
        (exit 0))
      (let* ((out (set-date msg))
             (tmp (string-append sent-dir "/tmp/" (unique-name)))
             (port (begin (write-bytes-string tmp out)
                          (open-pipe* OPEN_WRITE "msmtp" "-a" "mailfence" "-t")))
             (_ (begin (set-port-encoding! port "ISO-8859-1") (put-string port out)))
             (status (status:exit-val (close-pipe port))))
        (unless (eqv? status 0)
          (delete-file tmp)
          (die "msmtp exit ~a; draft kept, NOT retried.  See ~~/.cache/msmtp.log: an error after DATA can still mean it was sent" status))
        (format #t "Gesendet.~%")
        (force-output)
        (let* ((saved?
                (after-send (string-append "Sent-Kopie ablegen (gesichert in " tmp ")")
                  (lambda ()
                    (rename-file tmp (string-append sent-dir "/cur/"
                                                    (unique-name) ":2,S")))))
               ;; Trashed: Expunge Both removes the draft on the server.
               (trashed?
                (and saved?
                     (after-send "Entwurf entfernen"
                       (lambda ()
                         (let ((target (trashed-maildir-path draft)))
                           (unless (string=? draft target)
                             (when (file-exists? target)
                               (error "trash target already exists" target))
                             (rename-file draft target))))))))
        ;; notmuch indexed the draft under this Message-ID with tag "draft"; with
        ;; maildir.synchronize_flags it would re-add the D flag to the Sent copy, and
        ;; mbsync would upload it as \Draft.  Retag before the upload.
          (when (and saved?
                     (after-send "Sent-Kopie indizieren"
                       (lambda () (checked-command "notmuch" "new" "--quiet")))
                     (after-send "Entwurfsmarkierung der Sent-Kopie entfernen"
                       (lambda ()
                         (checked-command "notmuch" "tag" "-draft" "+sent"
                                          "--" (string-append "id:" id)))))
            (when (after-send "Sent-Kopie hochladen"
                    (lambda ()
                      (checked-command "mbsync" "mailfence-sent" "mailfence-drafts")))
              (format #t "In Mailfence unter Sent Items~a.~%"
                      (if trashed? ", Entwurf entfernt" "; Entwurf bitte manuell entfernen")))
            (after-send "Mailindex aktualisieren"
              (lambda () (checked-command "notmuch" "new" "--quiet")))))))))

(main (command-line))
