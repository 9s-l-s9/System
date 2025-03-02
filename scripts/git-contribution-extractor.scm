#!/usr/bin/env guile
!#

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 textual-ports)
             (srfi srfi-1)   ; List library
             (ice-9 getopt-long)
             (ice-9 format)
             (ice-9 ftw))    ; File tree walk

;; Function to parse ISO 8601 date string (YYYY-MM-DDTHH:MM:SS+ZZZZ)
;; Returns just the date part (YYYY-MM-DD)
(define (parse-iso-date date-string)
  (let ((match (string-match "([0-9]{4}-[0-9]{2}-[0-9]{2})T" date-string)))
    (if match
        (match:substring match 1)
        (begin
          (display "Warning: Could not parse date: ")
          (display date-string)
          (newline)
          #f))))

;; Function to execute a shell command and get output
(define (execute-command command)
  (display (string-append "Executing: " command "\n"))
  (let* ((port (open-input-pipe command))
         (output (get-string-all port))
         (status (close-pipe port)))
    (display (string-append "Command exit status: " (number->string status) "\n"))
    (if (= status 0)
        output
        (begin
          (display "Command failed with non-zero exit status\n")
          #f))))

;; Function to extract commit counts by date from a git repository
(define (get-commit-counts repo-path author)
  (display "Extracting commit data...\n")
  
  ;; Save current directory
  (define original-dir (getcwd))
  
  ;; Change to repository directory
  (display (string-append "Changing to directory: " repo-path "\n"))
  (chdir repo-path)
  
  (let ((contribution-data '()))
    (catch #t
      (lambda ()
        ;; First check if we're in a git repo with a simpler command
        (display "Checking git repository status...\n")
        (let ((git-status (execute-command "git status --porcelain")))
          (if (not git-status)
              (display "Warning: git status command failed. There may be issues with the repository.\n")
              (display "Git repository check successful.\n")))
        
        ;; Construct git log command
        (let* ((git-command (string-append
                             "git log --format=%aI --no-merges --all"
                             (if author
                                 (string-append " --author=\"" author "\"")
                                 "")))
               (output (execute-command git-command)))
          
          (if (not output)
              (display "No output from git log command.\n")
              (begin
                (display "Processing git log output...\n")
                (display (string-append "Output length: " (number->string (string-length output)) " characters\n"))
                
                ;; Process each line of git log output
                (for-each
                 (lambda (line)
                   (unless (string-null? line)
                     (let ((date-str (parse-iso-date line)))
                       (when date-str
                         (let ((existing-entry (assoc date-str contribution-data)))
                           (if existing-entry
                               ;; Update existing date entry
                               (set-cdr! existing-entry (1+ (cdr existing-entry)))
                               ;; Add new date entry
                               (set! contribution-data (cons (cons date-str 1) contribution-data))))))))
                 (string-split output #\newline))))))
      
      ;; Error handler
      (lambda (key . args)
        (display "Error in git command: ")
        (display args)
        (newline)))
    
    ;; Restore original directory
    (display (string-append "Returning to directory: " original-dir "\n"))
    (chdir original-dir)
    
    contribution-data))

;; Function to save contribution data as CSV
(define (save-contribution-data-csv contribution-data output-file)
  (display (string-append "Saving data to " output-file "...\n"))
  
  (catch #t
    (lambda ()
      (with-output-to-file output-file
        (lambda ()
          ;; Write CSV header
          (display "date,commits\n")
          
          ;; Sort data by date and write each entry
          (for-each
           (lambda (entry)
             (display (car entry))
             (display ",")
             (display (cdr entry))
             (newline))
           (sort contribution-data
                 (lambda (a b) (string<? (car a) (car b))))))))
    
    ;; Error handler
    (lambda (key . args)
      (display "Error saving data: ")
      (display args)
      (newline))))

;; Function to check if path is a git repository
(define (is-git-repo? path)
  (let ((git-dir (string-append path "/.git")))
    (if (file-exists? git-dir)
        (begin
          (display (string-append "Confirmed " path " is a git repository.\n"))
          #t)
        (begin
          (display (string-append "Directory " path " exists: " (if (file-exists? path) "yes" "no") "\n"))
          (display (string-append "Contents of " path ":\n"))
          (for-each (lambda (file) (display (string-append "  " file "\n")))
                    (scandir path (lambda (name) (not (member name '("." ".."))))))
          #f))))

;; Main function
(define (main args)
  (let* ((option-spec '((output (single-char #\o) (value #t))
                         (author (value #t))
                         (help (single-char #\h) (value #f))))
         (options (getopt-long args option-spec))
         (repo-path (if (null? (option-ref options '() '()))
                       "."
                       (car (option-ref options '() '()))))
         (output-file (option-ref options 'output "contribution_data.csv"))
         (author (option-ref options 'author #f))
         (help-flag (option-ref options 'help #f)))
    
    (display "Git Contribution Tracker\n")
    (display "------------------------\n")
    (display (string-append "Repository path: " repo-path "\n"))
    (display (string-append "Output file: " output-file "\n"))
    (when author
      (display (string-append "Author filter: " author "\n")))
    (display "------------------------\n")
    
    ;; Display help
    (when help-flag
      (display "Usage: git-contribution-tracker [OPTIONS] REPO_PATH\n")
      (display "Extract git repository contribution data\n\n")
      (display "Options:\n")
      (display "  --output, -o FILE    Output CSV file (default: contribution_data.csv)\n")
      (display "  --author PATTERN     Filter commits by author (email or name)\n")
      (display "  --help, -h           Display this help message\n")
      (exit 0))
    
    ;; Check if repo-path exists
    (unless (file-exists? repo-path)
      (display "Error: ")
      (display repo-path)
      (display " does not exist\n")
      (exit 1))
    
    ;; Check if repo-path is a git repository
    (unless (is-git-repo? repo-path)
      (display "Error: ")
      (display repo-path)
      (display " is not a git repository\n")
      (exit 1))
    
    ;; Extract and save contribution data
    (catch #t
      (lambda ()
        (let ((contribution-data (get-commit-counts repo-path author)))
          (display (string-append "Found " (number->string (length contribution-data)) " data points.\n"))
          (save-contribution-data-csv contribution-data output-file)
          
          ;; Display summary
          (display (string-append "Contributions saved to " output-file "\n"))
          (display (string-append "Found commits on " 
                                  (number->string (length contribution-data))
                                  " unique days.\n\n"))
          
          ;; Display sample data
          (display "Sample data:\n")
          (let ((sorted-data (sort contribution-data
                                   (lambda (a b) (string>? (car a) (car b))))))
            (for-each
             (lambda (entry)
               (display (car entry))
               (display ": ")
               (display (cdr entry))
               (display " commits\n"))
             (take sorted-data (min 5 (length sorted-data)))))))
      
      ;; Error handler
      (lambda (key . args)
        (display "Error: ")
        (display args)
        (newline)
        (exit 1)))
    
    0))

;; Call main function with command line arguments
(exit (main (command-line)))
