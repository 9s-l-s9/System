#!/usr/bin/env -S guile -s
!#

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (srfi srfi-1)
             (srfi srfi-13))

(define allowed-suffixes
  '(".scm" ".org"))

(define (read-lines port)
  (let loop ((lines '()))
    (let ((line (read-line port)))
      (if (eof-object? line)
          (reverse lines)
          (loop (cons (string-trim-right line) lines))))))

(define (git-script-files)
  (let* ((port (open-pipe* OPEN_READ "git" "ls-files" "scripts"))
         (lines (read-lines port))
         (status (close-pipe port)))
    (if (zero? status)
        lines
        (begin
          (format (current-error-port)
                  "check-guile-only: failed to list tracked script files.~%")
          (exit 1)))))

(define (allowed-script-file? path)
  (any (lambda (suffix) (string-suffix? suffix path))
       allowed-suffixes))

(define (main)
  (let ((violations (filter (lambda (path)
                              (not (allowed-script-file? path)))
                            (git-script-files))))
    (if (null? violations)
        (begin
          (format #t "Guile-only script policy check passed.~%")
          (exit 0))
        (begin
          (format (current-error-port)
                  "Guile-only script policy violation(s):~%")
          (for-each (lambda (path)
                      (format (current-error-port) "  ~a~%" path))
                    violations)
          (exit 1)))))

(main)
