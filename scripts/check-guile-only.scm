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

(define (run-git . args)
  (let* ((port (apply open-pipe* OPEN_READ "git" args))
         (lines (read-lines port))
         (status (close-pipe port)))
    (if (zero? status)
        lines
        (begin
          (format (current-error-port)
                  "check-guile-only: failed to run: git ~a~%"
                  (string-join args " "))
          (exit 1)))))

(define (git-script-files)
  "Tracked script files."
  (run-git "ls-files" "scripts"))

(define (git-untracked-script-files)
  "Untracked, non-ignored script files (so a stray .sh is caught before
commit, not just after)."
  (run-git "ls-files" "--others" "--exclude-standard" "scripts"))

(define (allowed-script-file? path)
  (any (lambda (suffix) (string-suffix? suffix path))
       allowed-suffixes))

(define (main)
  (let ((violations (filter (lambda (path)
                              (not (allowed-script-file? path)))
                            (append (git-script-files)
                                    (git-untracked-script-files)))))
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
