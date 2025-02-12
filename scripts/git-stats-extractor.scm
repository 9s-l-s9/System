;; Currently rewriting from python to guile scheme. Not yet working

(use-modules (ice-9 popen)
            (ice-9 rdelim)
            (ice-9 regex)
            (ice-9 format)
            (srfi srfi-19)  ; For date/time functions
            (ice-9 getopt-long))

;; Helper function to get current working directory
(define (getcwd)
  (let ((port (open-input-pipe "pwd")))
    (let ((dir (read-line port)))
      (close-pipe port)
      dir)))

;; Function to parse ISO date string into date object
(define (parse-iso-date date-string)
  (string->date date-string "~Y-~m-~dT~H:~M:~S~z"))

;; Format date as YYYY-MM-DD
(define (format-date date)
  (date->string date "~Y-~m-~d"))

;; Get commit counts from git repository
(define* (get-commit-counts repo-path #:optional author)
  (let* ((original-dir (getcwd))
         (contribution-data (make-hash-table)))
    (chdir repo-path)
    (let* ((git-command 
            (string-append
              "git log --format=%aI --no-merges --all"
              (if author 
                  (string-append " --author '" author "'")
                  "")))
           (port (open-input-pipe git-command))
           (process-line
            (lambda (line)
              (let* ((date (parse-iso-date line))
                     (date-str (format-date date))
                     (current-count (hash-ref contribution-data date-str 0)))
                (hash-set! contribution-data date-str (1+ current-count))))))
      
      ;; Process each line from git log
      (let loop ((line (read-line port)))
        (if (not (eof-object? line))
            (begin
              (process-line line)
              (loop (read-line port)))))
      
      (close-pipe port)
      (chdir original-dir)
      contribution-data)))

;; Save contribution data to CSV
(define (save-contribution-data-csv contribution-data output-file)
  (with-output-to-file output-file
    (lambda ()
      (display "date,commits\n")
      (let ((sorted-data
             (sort 
               (hash-map->list cons contribution-data)
               (lambda (a b) (string<? (car a) (car b))))))
        (for-each
          (lambda (entry)
            (format #t "~a,~a\n" (car entry) (cdr entry)))
          sorted-data)))))

;; Check if path is a git repository
(define (git-repo? path)
  (let ((git-dir (string-append path "/.git")))
    (access? git-dir F_OK)))


(define (main args)
  (let* ((option-spec '((output (single-char #\o) (value #t))
                       (author (value #t))))
         (options (getopt-long args option-spec))
         (repo-path (cadr args))
         (output-file (option-ref options 'output "contribution_data.csv"))
         (author (option-ref options 'author #f)))
    
    (if (not (git-repo? repo-path))
        (begin
          (format #t "Error: ~a is not a git repository~%" repo-path)
          1)
        (begin
          (catch #t
            (lambda ()
              (let ((contribution-data (get-commit-counts repo-path author)))
                (save-contribution-data-csv contribution-data output-file)
                (format #t "Contributions saved to ~a~%" output-file)
                (format #t "Found commits on ~a unique days.~%" 
                        (hash-count (const #t) contribution-data))
                (format #t "~%Sample data:~%")
                (let ((sorted-data
                       (take (sort 
                              (hash-map->list cons contribution-data)
                              (lambda (a b) (string>? (car a) (car b))))
                            5)))
                  (for-each
                    (lambda (entry)
                      (format #t "~a: ~a commits~%" (car entry) (cdr entry)))
                    sorted-data))
                0))
            (lambda (key . args)
              (format #t "Error: ~a~%" (car args))
              1))))))

(exit (main (command-line)))
