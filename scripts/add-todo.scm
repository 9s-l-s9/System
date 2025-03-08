#!/usr/bin/env guile
!#

(use-modules (ice-9 format)
             (srfi srfi-19))

(define (write-to-org-file text file-path)
  "Write a string to an org-mode file with current date and star heading.
   Arguments:
     text: The string to write to the file
     file-path: Path to the org-mode file"
  
  (let* ((current-date (current-date))
         (formatted-date (date->string current-date "~Y-~m-~d"))
         (org-entry (string-append "* TODO " formatted-date " " text))
         (port (open-file file-path "a")))  ; Open file in append mode
    
    (format port "~a~%~%" org-entry)
    
    (close-port port)
    
    (format #t "Successfully wrote entry to ~a~%" file-path)))

(define (main args)
  (if (< (length args) 3)
      (begin
        (format #t "Usage: ~a \"Your note text\" path/to/file.org~%" (car args))
        (exit 1))
      (write-to-org-file (cadr args) (caddr args))))

;; Call main with command-line arguments
(main (command-line))
