#!/usr/bin/env -S guile -s
!#
;;; Compile-check scripts/ for unbound variables, arity mismatches, and syntax
;;; errors.  Pure-Guile scripts are compiled everywhere (including CI); scripts
;;; importing (guix ...) are compiled whenever Guix is on Guile's load path.

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (srfi srfi-1)
             (srfi srfi-13))

(define optional-module-scripts
  '((("scripts/lib/minde-binary.scm"
      "scripts/minde-binary.scm"
      "scripts/test-minde-binary.scm")
     . "guix/packages.scm")
    (("scripts/ask-ai.scm"
      "scripts/mail-export.scm")
     . "json.scm")))

(define (missing-dependency? path)
  (any (lambda (entry)
         (and (member path (car entry))
              (not (search-path %load-path (cdr entry)))))
       optional-module-scripts))

(define (run-lines program . args)
  (let* ((port (apply open-pipe* OPEN_READ program args))
         (output (read-string port))
         (status (close-pipe port)))
    (values (status:exit-val status) output)))

(define (git-scm-files)
  (call-with-values
      (lambda ()
        (run-lines "git" "ls-files" "--cached" "--others" "--exclude-standard"
                   "scripts"))
    (lambda (code output)
      (unless (zero? code)
        (format (current-error-port) "check-scripts-compile: git ls-files failed~%")
        (exit 1))
      (delete-duplicates
       (filter (lambda (path)
                 (and (string-suffix? ".scm" path)
                      (file-exists? path)))
               (string-split (string-trim-right output) #\newline))))))

(define (guild-program)
  ;; Debian/Ubuntu install guild as guild-3.0 (guild only via alternatives).
  (or (find (lambda (name)
              (zero? (status:exit-val
                      (system (string-append "command -v " name " >/dev/null 2>&1")))))
            '("guild" "guild-3.0"))
      (begin
        (format (current-error-port) "check-scripts-compile: guild not found~%")
        (exit 1))))

(define (compile-diagnostics path temp-go)
  ;; Capture both stdout and stderr from guild compile; fail on non-zero exit
  ;; or any compiler warning (`;;; file:line:col: warning: ...`), since guild
  ;; exits 0 on unbound-variable and arity warnings.
  (let* ((quoted-path (string-append "'" (string-join (string-split path #\') "'\\''") "'"))
         (quoted-go (string-append "'" (string-join (string-split temp-go #\') "'\\''") "'"))
         (cmd (string-append (guild-program) " compile -L scripts/lib"
                             " -Wunbound-variable -Warity-mismatch -Wformat"
                             " -o " quoted-go " " quoted-path " 2>&1"))
         (port (open-input-pipe cmd))
         (output (read-string port))
         (code (status:exit-val (close-pipe port))))
    (cons (and (zero? code)
               (not (string-match ": warning:" output)))
          output)))

(define (main)
  (let* ((port (mkstemp "/tmp/check-scripts-compile-XXXXXX"))
         (temp-go (port-filename port))
         (files (git-scm-files))
         (failures '())
         (checked 0)
         (skipped 0))
    (close-port port)
    (for-each
     (lambda (path)
       (if (missing-dependency? path)
           (set! skipped (+ skipped 1))
           (let ((res (compile-diagnostics path temp-go)))
             (set! checked (+ checked 1))
             (unless (car res)
               (set! failures (cons (cons path (cdr res)) failures))))))
     files)
    (when (file-exists? temp-go)
      (delete-file temp-go))
    (if (null? failures)
        (begin
          (format #t "Guile script compilation check passed (~a compiled~a).~%"
                  checked
                  (if (zero? skipped)
                      ""
                      (format #f ", ~a external-module script(s) skipped" skipped)))
          (exit 0))
        (begin
          (format (current-error-port)
                  "Guile script compilation check failed:~%")
          (for-each
           (lambda (entry)
             (format (current-error-port) "=== ~a ===~%~a" (car entry) (cdr entry)))
           (reverse failures))
          (exit 1)))))

(main)
