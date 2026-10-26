#!/usr/bin/env -S guix repl -q --
!#
(add-to-load-path (dirname (current-filename)))
(use-modules (lib minde-binary)
             (srfi srfi-64)
             (ice-9 textual-ports)
             (guix build utils)
             ((guix build syscalls) #:select (mkdtemp!)))

(define directory (mkdtemp! "/tmp/test-minde-binary.XXXXXX"))
(define metadata-file (string-append directory "/binary.scm"))
(define valid
  `((schema . 1) (repository . "9s-l-s9/minde")
    (commit . ,(make-string 40 #\a)) (version . "1.0.0-rc1")
    (system . "x86_64-linux")
    (minde . ,(string-append "/gnu/store/" (make-string 32 #\a) "-minde-1.0.0-rc1"))
    (xwayland . ,(string-append "/gnu/store/" (make-string 32 #\b) "-xorg-server-xwayland-24.1"))
    (archive-sha256 . ,(make-string 64 #\a))
    (key-sha256 . ,(make-string 64 #\b))
    (closure-sha256 . ,(make-string 64 #\c))))

(define (metadata value)
  (call-with-output-file metadata-file (lambda (port) (write value port)))
  (read-metadata metadata-file))

(define-syntax-rule (rejects name body ...)
  (test-assert name (catch #t (lambda () body ... #f) (lambda _ #t))))

(test-begin "minde-binary")
(test-equal "valid metadata" valid (metadata valid))
(rejects "reject duplicate fields"
  (metadata (cons '(schema . 1) valid)))
(rejects "reject unknown fields"
  (metadata (cons '(run . "malicious-command") valid)))
(rejects "reject repository substitution"
  (metadata (acons 'repository "attacker/minde" (assq-delete-all 'repository valid))))
(rejects "reject architecture substitution"
  (metadata (acons 'system "aarch64-linux" (assq-delete-all 'system valid))))
(rejects "reject store path traversal"
  (metadata (acons 'minde "/gnu/store/../etc" (assq-delete-all 'minde valid))))
(rejects "reject abbreviated commit"
  (metadata (acons 'commit "abc123" (assq-delete-all 'commit valid))))
(rejects "reject executable Scheme instead of data"
  (metadata '(begin (system "false") '())))
(rejects "reject trailing expression"
  (call-with-output-file metadata-file
    (lambda (port) (write valid port) (display "\n(system \"false\")" port)))
  (read-metadata metadata-file))
(rejects "reject malformed digest"
  (metadata (acons 'key-sha256 "checksum" (assq-delete-all 'key-sha256 valid))))
(test-assert "reject non-store paths" (not (store-item? "/tmp/minde")))
(test-assert "reject paths inside a store item"
  (not (store-item? (string-append (assoc-ref valid 'minde) "/bin/minde"))))
(let ((closure-file (string-append directory "/closure.txt")))
  (call-with-output-file closure-file
    (lambda (port)
      (display (assoc-ref valid 'minde) port) (newline port)
      (display (assoc-ref valid 'xwayland) port) (newline port)))
  (test-equal "complete closure" 2 (length (read-closure closure-file valid)))
  (call-with-output-file closure-file
    (lambda (port) (display (assoc-ref valid 'minde) port) (newline port)))
  (rejects "reject missing propagated runtime" (read-closure closure-file valid)))
(let ((bundle (set-download-trust! (string-append directory "/trust"))))
  (test-assert "filtered CA bundle exists" (> (stat:size (stat bundle)) 10000))
  (test-equal "empty fallback certificate directory"
    (string-append directory "/trust/empty") (getenv "SSL_CERT_DIR")))
(let ((bad-ca (string-append directory "/bad-ca.pem")))
  (call-with-output-file bad-ca (lambda (port) (display "not a certificate" port)))
  (rejects "empty CA store fails closed"
    (set-download-trust! (string-append directory "/bad-trust") bad-ca)))
(define failures (test-runner-fail-count (test-runner-current)))
(test-end "minde-binary")
(delete-file-recursively directory)
(exit (if (zero? failures) 0 1))
