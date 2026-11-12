#!/usr/bin/env -S guile -s
!#
;;; Synthetic Maildirs only. SMTP and IMAP commands are always fake programs.
(add-to-load-path (dirname (or (current-filename) "scripts/test-mail-workflows.scm")))
(use-modules (lib maildir) (ice-9 ftw) (ice-9 popen) (ice-9 textual-ports)
             (srfi srfi-1) (srfi srfi-13) (srfi srfi-64))

(define repository (dirname (dirname (canonicalize-path (current-filename)))))
(define reservation (mkstemp "/tmp/system-mail-tests.XXXXXX"))
(define directory (port-filename reservation))
(close-port reservation)
(delete-file directory)
(mkdir directory #o700)
(define store (string-append directory "/Mail/mailfence"))
(define bin (string-append directory "/bin"))
(define calls (string-append directory "/calls"))
(define smtp-copy (string-append directory "/smtp-message"))
(define guile (readlink "/proc/self/exe"))
(define real-notmuch (search-path (string-split (getenv "PATH") #\:) "notmuch"))
(define real-w3m (search-path (string-split (getenv "PATH") #\:) "w3m"))
(unless (and real-notmuch real-w3m) (error "tests need notmuch and w3m"))

(define (mkdir-p path)
  (unless (file-exists? path) (mkdir-p (dirname path)) (mkdir path #o700)))
(define (put-file path text)
  (call-with-output-file path (lambda (port) (display text port))))
(define (get-file path) (call-with-input-file path get-string-all))
(define (files path)
  (map (lambda (name) (string-append path "/" name))
       (or (scandir path (lambda (name) (not (member name '("." ".."))))) '())))
(define (write-program name . forms)
  (let ((path (string-append bin "/" name)))
    (call-with-output-file path
      (lambda (port)
        (format port "#!~a -s\n!#\n" guile)
        (for-each (lambda (form) (write form port) (newline port)) forms)))
    (chmod path #o700)))
(define log-call
  `(let ((port (open-file ,calls "a")))
     (write (cons (basename (car (command-line))) (cdr (command-line))) port)
     (newline port) (close-port port)))

(mkdir bin)
(mkdir-p (string-append directory "/run"))
(mkdir-p (string-append directory "/config"))
(mkdir-p (string-append directory "/hooks"))
(for-each
 (lambda (folder)
   (for-each (lambda (sub) (mkdir-p (string-append store "/" folder "/" sub)))
             '("cur" "new" "tmp")))
 '("INBOX" "Wichtig" "Drafts" "Sent Items"))
(put-file (string-append directory "/notmuch-config")
          (string-append "[database]\npath=" store "\nhook_dir=" directory "/hooks"
                         "\n[user]\nname=Test\nprimary_email=test@example.invalid\n"
                         "[new]\ntags=new;\n[maildir]\nsynchronize_flags=true\n"))
(define environment
  (list (string-append "HOME=" directory)
        (string-append "NOTMUCH_CONFIG=" directory "/notmuch-config")
        (string-append "XDG_CONFIG_HOME=" directory "/config")
        (string-append "XDG_RUNTIME_DIR=" directory "/run")
        (string-append "PATH=" bin ":" (getenv "PATH")) "GUILE_AUTO_COMPILE=0"))

(write-program "mbsync" log-call '(exit 0))
(write-program "msmtp"
 '(use-modules (ice-9 textual-ports)) log-call
 `(call-with-output-file ,smtp-copy
    (lambda (port) (display (get-string-all (current-input-port)) port)))
 '(exit (if (getenv "MAIL_TEST_SMTP_FAIL") 1 0)))
(write-program "notmuch"
 log-call
 `(cond
   ((and (getenv "MAIL_TEST_BAD_JSON") (member "show" (command-line))
         (member "--format=json" (command-line))
         (member "id:\"broken@example.invalid\"" (command-line)))
    (display "invalid JSON") (exit 0))
   ((and (getenv "MAIL_TEST_TAG_FAIL") (member "tag" (command-line))) (exit 1))
   (else (apply execl ,real-notmuch ,real-notmuch (cdr (command-line))))))
(write-program "w3m"
 '(use-modules (ice-9 textual-ports))
 `(if (getenv "MAIL_TEST_HTML_FAIL")
      (exit 1)
      (apply execl ,real-w3m ,real-w3m (cdr (command-line)))))

(define* (run args #:optional (extra '()))
  (let* ((port (apply open-pipe* OPEN_READ "env"
                      (append environment extra args)))
         (text (get-string-all port))
         (status (status:exit-val (close-pipe port))))
    (cons status text)))
(define (ok args)
  (let ((result (run args)))
    (unless (eqv? 0 (car result)) (error "fixture command failed" args result))
    (cdr result)))
(define (script name . args)
  (append (list guile "--no-auto-compile" (string-append repository "/scripts/" name)) args))
(define* (message id subject body #:optional (headers "Content-Type: text/plain\n"))
  (string-append "From: Test <test@example.invalid>\nTo: Recipient <to@example.invalid>\n"
                 "Message-ID: <" id ">\nDate: Thu, 12 Nov 2026 10:00:00 +0000\n"
                 "Subject: " subject "\n" headers "\n" body "\n"))
(define (indexed? query)
  (string=? "1\n" (ok (list "notmuch" "count" query))))

;; Guile versions differ in their logging controls; keep any default log in
;; the disposable fixture directory instead of using test-log-to-file.
(let ((original-directory (getcwd)))
  (dynamic-wind
    (lambda () (chdir directory))
    (lambda () (test-begin "mail-workflows"))
    (lambda () (chdir original-directory))))
(dynamic-wind
  (lambda () #t)
  (lambda ()
    (for-each
     (lambda (entry)
       (test-equal "trash path handles missing and sorted flags" (cdr entry)
                   (trashed-maildir-path (car entry))))
     '(("/mail/Drafts/new/name" . "/mail/Drafts/cur/name:2,T")
       ("/mail/Drafts/cur/name" . "/mail/Drafts/cur/name:2,T")
       ("/mail/Drafts/cur/name:2,SR" . "/mail/Drafts/cur/name:2,RST")
       ("/mail/Drafts/cur/name:2,ST" . "/mail/Drafts/cur/name:2,ST")
       ("/tmp/draft:other.eml" . "/tmp/draft:other.eml:2,T")))
    (for-each
     (lambda (entry)
       (let* ((id (string-append (car entry) "@example.invalid"))
              (draft (string-append store "/Drafts/" (cdr entry))))
         (put-file draft (message id "draft" "body"))
         (ok '("notmuch" "new" "--no-hooks"))
         (ok (list "notmuch" "tag" "+draft" "--" (string-append "id:" id)))
         (let ((result (run (script "mail-send.scm" "--confirm" id))))
           (test-equal "send succeeds" 0 (car result))
           (test-assert "delivery acknowledged" (string-contains (cdr result) "Gesendet."))
           (test-assert "draft moved to cur with trash flag"
             (any (lambda (file)
                    (and (string-prefix? (car entry) (basename file))
                         (string-suffix? "T" file)))
                  (files (string-append store "/Drafts/cur"))))
           (test-assert "sent mail is retagged before upload"
             (indexed? (string-append "id:" id " and tag:sent and not tag:draft")))
           (test-assert "SMTP receives draft body" (string-contains (get-file smtp-copy) "body"))
           (test-assert "second send refused"
             (not (eqv? 0 (car (run (script "mail-send.scm" "--confirm" id)))))))))
     '(("fresh" . "new/fresh") ("seen" . "cur/seen:2,DS")))
    ;; A collision makes draft removal fail after SMTP; indexing/upload still run.
    (let ((draft (string-append store "/Drafts/new/collision")))
      (put-file draft (message "collision@example.invalid" "collision" "body"))
      (put-file (trashed-maildir-path draft) (message "other@example.invalid" "other" "body"))
      (put-file calls "")
      (let ((result (run (script "mail-send.scm" "--confirm" draft))))
        (test-equal "cleanup failure does not disguise SMTP success" 0 (car result))
        (test-assert "cleanup failure still reports sent" (string-contains (cdr result) "Gesendet."))
        (test-assert "upload follows cleanup failure" (string-contains (get-file calls) "mailfence-sent"))
        (test-assert "existing trash target not overwritten"
          (string-contains (get-file (trashed-maildir-path draft)) "other@example.invalid"))))
    (let ((draft (string-append store "/Drafts/new/failed")))
      (put-file draft (message "failed@example.invalid" "failed" "body"))
      (test-assert "SMTP failure returns failure"
        (not (eqv? 0 (car (run (script "mail-send.scm" "--confirm" draft)
                              '("MAIL_TEST_SMTP_FAIL=1"))))))
      (test-assert "failed send retains draft" (file-exists? draft)))
    ;; Real notmuch gives realistic JSON/query/flag semantics. Only one show
    ;; response is corrupted, and HTML conversion is made to fail separately.
    (put-file (string-append store "/INBOX/new/broken")
              (message "broken@example.invalid" "broken" "bad"))
    (put-file (string-append store "/Wichtig/new/good")
              (message "good@example.invalid" "good" "readable text"))
    (put-file (string-append store "/INBOX/new/html")
              (message "html@example.invalid" "html" "<p>HTML body</p>"
                       "Content-Type: text/html; charset=UTF-8\n"))
    (put-file (string-append store "/INBOX/new/attachment")
              (message "attachment@example.invalid" "attachment"
                       "--boundary\nContent-Type: text/plain\n\nbody\n--boundary\nContent-Type: application/octet-stream\nContent-Disposition: attachment; filename=\"..\"\n\npayload\n--boundary--"
                       "MIME-Version: 1.0\nContent-Type: multipart/mixed; boundary=boundary\n"))
    (ok '("notmuch" "new" "--no-hooks"))
    (test-equal "bad JSON and failed HTML do not stop export" 0
      (car (run (script "mail-export.scm") '("MAIL_TEST_BAD_JSON=1" "MAIL_TEST_HTML_FAIL=1"))))
    (test-assert "malformed message tagged for explicit retry"
      (indexed? "id:broken@example.invalid and tag:export-failed and not tag:new"))
    (test-assert "HTML error tagged for retry"
      (indexed? "id:html@example.invalid and tag:export-failed and not tag:new"))
    (test-assert "Wichtig mail tagged inbox and queue drained"
      (indexed? "id:good@example.invalid and tag:inbox and not tag:new"))
    (test-equal "HTML temporary files removed on error" '()
      (files (string-append directory "/run")))
    (let* ((exports (files (string-append directory "/Mail/text/2026")))
           (text-files (filter (lambda (file) (string-suffix? ".txt" file)) exports)))
      (test-assert "good message after broken one exported"
        (any (lambda (file) (string-contains (get-file file) "readable text")) text-files))
      (test-assert "unsafe attachment name replaced with safe filename"
        (any (lambda (path)
               (and (file-is-directory? path)
                    (any (lambda (file)
                           (and (string-prefix? "attachment-" (basename file))
                                (string-contains (get-file file) "payload")))
                         (files path))))
             exports)))
    (test-equal "retry exports repaired messages" 0
      (car (run (script "mail-export.scm" "tag:export-failed"))))
    (test-equal "success clears failure tags" "0\n" (ok '("notmuch" "count" "tag:export-failed")))
    (test-equal "HTML temporary files removed on success" '()
      (files (string-append directory "/run"))))
  (lambda () (system* "rm" "-rf" "--" directory)))
(define failures (test-runner-fail-count (test-runner-current)))
(test-end "mail-workflows")
(exit (if (zero? failures) 0 1))
