#!/usr/bin/env -S guile -s
!#
;;; mail-draft --- turn a plain-text file into a Mailfence draft
;;;
;;; Input: a text file with a few header lines, a blank line, then the body:
;;;
;;;   To: Matthias Wegerle <matthias.wegerle@docmorris.de>
;;;   Subject: Re: Kennenlernen mit Gowan
;;;   In-Reply-To: <CAxyz@mail.gmail.com>
;;;
;;;   Hallo Matthias,
;;;   ...
;;;
;;; Only In-Reply-To is needed for a reply: To and Subject then default to
;;; the original's Reply-To/From and "Re: <subject>", and References is
;;; rebuilt from the original so the reply threads correctly.  Cc is
;;; optional.
;;;
;;; The draft is written into ~/Mail/mailfence/Drafts and uploaded with
;;; `mbsync mailfence-drafts'.  It is never sent: review and send it in
;;; Mailfence (web, app) or Emacs.
;;;
;;; Usage: mail-draft.scm [--no-sync] FILE

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 textual-ports)
             (rnrs bytevectors)
             (srfi srfi-1)
             (srfi srfi-13))

(fluid-set! %default-port-encoding "UTF-8")
(unless (string-contains-ci (or (false-if-exception (setlocale LC_ALL "")) "") "UTF-8")
  (false-if-exception (setlocale LC_ALL "C.UTF-8")))

(define from-address
  (string-append "Samuel Levi Schmidt <samuel" "@" "schmidt-contact.com>"))
(define drafts-dir
  (string-append (getenv "HOME") "/Mail/mailfence/Drafts"))

(define (die fmt . args)
  (apply format (current-error-port) (string-append "mail-draft: " fmt "~%") args)
  (exit 1))

(define (command-output program . args)
  (let* ((port (apply open-pipe* OPEN_READ program args))
         (out (get-string-all port)))
    (close-pipe port)
    out))

;;; Parsing

(define (split-header-block text)
  "Return (headers . body); headers is an alist with downcased keys."
  (let* ((end (or (string-contains text "\n\n") (string-length text)))
         (head (substring text 0 end))
         (body (if (< end (string-length text)) (substring text (+ end 2)) "")))
    (cons (filter-map
           (lambda (line)
             (let ((colon (string-index line #\:)))
               (and colon
                    (cons (string-downcase (string-trim-both (substring line 0 colon)))
                          (string-trim-both (substring line (+ colon 1)))))))
           (string-split head #\newline))
          body)))

(define (header alist key)
  (let ((cell (assoc key alist)))
    (and cell (not (string-null? (cdr cell))) (cdr cell))))

(define (original-header msg-id name)
  "Header NAME of the message MSG-ID from the notmuch database, or #f."
  (let* ((raw (command-output "notmuch" "show" "--format=raw"
                              (string-append "id:" msg-id)))
         (end (or (string-contains raw "\n\n") (string-length raw)))
         (head (regexp-substitute/global #f "\r?\n[ \t]+" (substring raw 0 end)
                                         'pre " " 'post))
         (m (regexp-exec (make-regexp (string-append "(^|\n)" name ":[ \t]*([^\n]*)")
                                      regexp/icase)
                         head)))
    (and m (string-trim-both (match:substring m 2)))))

(define (bare-id id)
  (string-trim-both id (char-set #\< #\> #\space)))

;;; RFC 2047 encoding for non-ASCII header text

(define base64-chars
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

(define (base64 bv)
  (let ((len (bytevector-length bv)))
    (let loop ((i 0) (acc '()))
      (if (>= i len)
          (string-concatenate-reverse acc)
          (let* ((b0 (bytevector-u8-ref bv i))
                 (b1 (if (< (+ i 1) len) (bytevector-u8-ref bv (+ i 1)) 0))
                 (b2 (if (< (+ i 2) len) (bytevector-u8-ref bv (+ i 2)) 0))
                 (n (+ (ash b0 16) (ash b1 8) b2))
                 (c (lambda (shift) (string (string-ref base64-chars
                                                        (logand (ash n (- shift)) 63)))))
                 (chunk (string-append (c 18) (c 12)
                                       (if (< (+ i 1) len) (c 6) "=")
                                       (if (< (+ i 2) len) (c 0) "="))))
            (loop (+ i 3) (cons chunk acc)))))))

(define (ascii? s)
  (string-every (lambda (ch) (< (char->integer ch) 128)) s))

(define (encode-word s)
  (if (ascii? s)
      s
      (string-append "=?UTF-8?B?" (base64 (string->utf8 s)) "?=")))

(define (encode-addresses s)
  "Encode non-ASCII display names in a comma-separated address list."
  (string-join
   (map (lambda (addr)
          (let ((m (string-match "^[ \t]*\"?([^<\"]*)\"?[ \t]*<([^>]+)>" addr)))
            (if (and m (not (ascii? (match:substring m 1))))
                (string-append (encode-word (string-trim-both (match:substring m 1)))
                               " <" (match:substring m 2) ">")
                (string-trim-both addr))))
        (string-split s #\,))
   ", "))

;;; Building the message

(define (rfc2822-date)
  (setlocale LC_TIME "C")
  (strftime "%a, %d %b %Y %H:%M:%S %z" (localtime (current-time))))

(define (unique-name)
  (format #f "~a.~a_~a.~a" (current-time) (getpid) (random 1000000 (random-state-from-platform))
          (gethostname)))

(define (build-message headers body)
  (let* ((reply-to (let ((v (header headers "in-reply-to"))) (and v (bare-id v))))
         (to (or (header headers "to")
                 (and reply-to (or (original-header reply-to "Reply-To")
                                   (original-header reply-to "From")))
                 (die "no To: and no In-Reply-To: to take it from")))
         (subject (or (header headers "subject")
                      (and reply-to
                           (let ((s (or (original-header reply-to "Subject") "")))
                             (if (string-prefix-ci? "re:" s) s (string-append "Re: " s))))
                      (die "no Subject:")))
         (references (and reply-to
                          (string-trim-both
                           (string-append (or (original-header reply-to "References") "")
                                          " <" reply-to ">"))))
         (cc (header headers "cc"))
         (domain (let ((at (string-index from-address #\@)))
                   (string-trim-right (substring from-address (+ at 1)) #\>))))
    (string-append
     "Date: " (rfc2822-date) "\n"
     "From: " from-address "\n"
     "To: " (encode-addresses to) "\n"
     (if cc (string-append "Cc: " (encode-addresses cc) "\n") "")
     "Subject: " (encode-word subject) "\n"
     "Message-ID: <" (unique-name) "@" domain ">\n"
     (if reply-to (string-append "In-Reply-To: <" reply-to ">\n") "")
     (if references (string-append "References: " references "\n") "")
     "MIME-Version: 1.0\n"
     "Content-Type: text/plain; charset=utf-8\n"
     "Content-Transfer-Encoding: 8bit\n"
     "\n"
     (string-trim-right body) "\n")))

(define (write-draft message)
  ;; Maildir flags D (draft) and S (seen); mbsync uploads unnumbered files.
  (let ((file (string-append drafts-dir "/cur/" (unique-name) ":2,DS")))
    (unless (file-exists? (string-append drafts-dir "/cur"))
      (die "~a missing; run mbsync once first" drafts-dir))
    (call-with-output-file file (lambda (p) (put-string p message)))
    file))

(define (main args)
  (let* ((no-sync? (member "--no-sync" args))
         (files (remove (lambda (a) (string-prefix? "--" a)) (cdr args))))
    (unless (= (length files) 1)
      (die "usage: mail-draft.scm [--no-sync] FILE"))
    (let* ((parsed (split-header-block
                    (call-with-input-file (car files) get-string-all)))
           (file (write-draft (build-message (car parsed) (cdr parsed)))))
      (format #t "Entwurf: ~a~%" file)
      (unless no-sync?
        (system* "mbsync" "mailfence-drafts")
        (system* "notmuch" "new" "--quiet")
        (format #t "In Mailfence unter Drafts.~%")))))

(main (command-line))
