#!/usr/bin/env guile
!#

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 string-fun)
             (ice-9 ftw)
             (srfi srfi-1)
             (srfi srfi-19))

;; String utilities
(define (my-string-split str delim)
  "Split string by delimiter character and return a list of strings"
  (let loop ((chars (string->list str))
             (current "")
             (result '()))
    (cond
     ((null? chars)
      (reverse (cons current result)))
     ((char=? (car chars) delim)
      (loop (cdr chars)
            ""
            (cons current result)))
     (else
      (loop (cdr chars)
            (string-append current (string (car chars)))
            result)))))

(define (string-join lst delimiter)
  (if (null? lst)
      ""
      (let loop ((strs (cdr lst))
                 (result (car lst)))
        (if (null? strs)
            result
            (loop (cdr strs)
                  (string-append result delimiter (car strs)))))))

;; Terminal utilities
(define (get-terminal-size)
  "Get terminal width and height"
  (let* ((port (open-input-pipe "stty size"))
         (size (read-line port))
         (parts (my-string-split size #\space))
         (height (string->number (car parts)))
         (width (string->number (cadr parts))))
    (close-pipe port)
    (cons width height)))

(define (center-x str width)
  "Center text horizontally"
  (let* ((lines (my-string-split str #\newline))
         (first-line (car lines))
         (line-len (string-length first-line))
         (padding (quotient (- width line-len) 2)))
    (if (<= padding 0)
        ""
        (let ((pad-str (make-string padding #\space)))
          (string-join 
            (map (lambda (line) 
                   (string-append pad-str line)) 
                 lines) 
            "\n")))))

(define (center-y str height fill?)
  "Center text vertically"
  (let* ((lines (my-string-split str #\newline))
         (padding (+ 1 (quotient (- height (length lines)) 2)))
         (pad-str (make-string padding #\newline)))
    (if (<= padding 0)
        ""
        (string-append pad-str str (if fill? pad-str "")))))

(define (clear-screen)
  "Clear the terminal screen"
  (display "\033[2J\033[1;1H"))

(define (format-options options)
  "Format the menu options"
  (let loop ((opts options)
             (result "")
             (break-count 0))
    (if (null? opts)
        result
        (let* ((option (car opts))
               (name (car option))
               (icon (cadr option))
               (shortcut (caddr option))
               (command (cadddr option))
               (break-pad (if (= (modulo (+ break-count 1) 2) 0) "\n" "\t"))
               (formatted (format #f "~a ~a [:~a]~a" icon name shortcut break-pad)))
          (loop (cdr opts)
                (string-append result formatted)
                (+ break-count 1))))))

;; TODO utilities
(define (show-todos todo-file)
  "Show open TODOs from org file at TODO-FILE path.
   Returns a string of TODOs or 'No open TODOs' message."
  (let* ((todos (call-with-input-file todo-file
                  (lambda (port)
                    (let loop ((line (read-line port))
                               (results '()))
                      (if (eof-object? line)
                          (reverse results)
                          (let* ((cleaned-line (string-trim-both line))
                                 (is-todo? (and (> (string-length cleaned-line) 6)
                                               (char=? (string-ref cleaned-line 0) #\*)
                                               (let* ((asterisk-pattern (make-regexp "^\\*+[ \t]+"))
                                                      (match (regexp-exec asterisk-pattern cleaned-line)))
                                                 (and match
                                                      (let* ((content-start (match:end match))
                                                             (content (string-trim-both (substring cleaned-line content-start))))
                                                        (and (> (string-length content) 4)
                                                             (string=? "TODO" (substring content 0 4))))))))
                                 (todo-content (if is-todo?
                                                 (let* ((asterisk-pattern (make-regexp "^\\*+[ \t]+"))
                                                        (match (regexp-exec asterisk-pattern cleaned-line))
                                                        (content-start (match:end match))
                                                        (content (string-trim-both (substring cleaned-line content-start))))
                                                   (string-trim-both (substring content 4)))
                                                 #f)))
                            (loop (read-line port)
                                  (if is-todo?
                                      (cons todo-content results)
                                      results))))))))
         (todo-string (if (null? todos)
                          "No open TODOs"
                          (string-append "\n" (string-join todos "\n")))))
    todos))

(define (get-first-todo)
  "Returns the first TODO from org files or a message if none found"
  (let* ((org-files '("/home/samuel/Projects/WorkingMemory/wm-T450s.org"
                      "/home/samuel/Projects/WorkingMemory/wm-X1.org"
                      "/home/samuel/Projects/WorkingMemory/wm-palma.org"))
         (all-todos '()))
    
    ;; Try to get TODOs from each org file
    (for-each
     (lambda (file)
       (catch #t
              (lambda ()
                (let ((todos (show-todos file)))
                  (when (not (null? todos))
                    (set! all-todos (append all-todos todos)))))
              (lambda (key . args)
                #f)))
     org-files)
    
    ;; Return first TODO or message if none found
    (if (null? all-todos)
        "No pending TODOs"
        (string-append "Next TODO: " (car all-todos)))))

;; Download utilities
(define (get-downloads)
  "Returns a string listing files in the Downloads directory matching a simple pattern."
  (let* ((downloads-dir (string-append (getenv "HOME") "/Downloads"))
         (dir (opendir downloads-dir)))
    (let loop ((files '()))
      (let ((entry (readdir dir)))
        (if (eof-object? entry)
            (begin
              (closedir dir)
              (let ((filtered (filter (lambda (fname)
                                        (and (not (string=? fname "."))
                                             (not (string=? fname ".."))
                                             (string-contains fname ".")))
                                      (reverse files))))
                (if (null? filtered)
                    "Download directory is clean!"
                    (string-join filtered "\n"))))
            (loop (cons entry files)))))))

;; Git utilities
(define base-dir "/home/samuel/Projects")

(define (has-uncommitted-changes? repo-dir)
  (let* ((command (string-append "git -C " repo-dir " status --porcelain"))
         (port (open-input-pipe command))
         (output (read-string port)))
    (close-pipe port)
    (not (string-null? output))))

(define (is-git-repo? dir)
  (let ((git-dir (string-append dir "/.git")))
    (and (file-exists? git-dir) 
         (file-is-directory? git-dir))))

(define (get-uncommitted-changes)
  "Returns a string of git repositories with uncommitted changes."
  (let ((repos-with-changes '()))
    (ftw base-dir
         (lambda (file stat flag)
           (when (and (eq? flag 'directory)
                     (is-git-repo? file)
                     (has-uncommitted-changes? file))
             (set! repos-with-changes (cons file repos-with-changes)))
           #t))
    (if (null? repos-with-changes)
        "No uncommitted changes in any repositories."
        (string-join (reverse repos-with-changes) "\n"))))

;; Dashboard function
(define (generate-dashboard)
  "Generates comprehensive dashboard text including TODOs, git status, and downloads"
  (let* ((org-files '("/home/samuel/Projects/WorkingMemory/wm-T450s.org"
                      "/home/samuel/Projects/WorkingMemory/wm-X1.org"
                      "/home/samuel/Projects/WorkingMemory/wm-palma.org"))
         (todos-section 
          (string-append "=== TODOs ===\n"
                         (string-join 
                          (map (lambda (file)
                                (let ((filename (last (string-split file #\/))))
                                  (string-append "--- " filename " ---\n"
                                                (let ((todos (catch #t
                                                                 (lambda () 
                                                                   (let ((todo-items (show-todos file)))
                                                                     (if (null? todo-items)
                                                                         "No open TODOs"
                                                                         (string-append "\n" (string-join todo-items "\n")))))
                                                                 (lambda (key . args)
                                                                   (string-append "Error reading file: " 
                                                                                (symbol->string key))))))
                                    todos))))
                               org-files)
                          "\n\n")))
         (git-section 
          (string-append "=== Git Status ===\n" (get-uncommitted-changes)))
         (downloads-section 
          (string-append "=== Downloads ===\n" (get-downloads)))
         (dashboard-text 
          (string-append todos-section "\n\n" git-section "\n\n" downloads-section)))
    dashboard-text))

;; Main function
(define (main)
  (let* ((term-size (get-terminal-size))
         (width (car term-size))
         (height (cdr term-size))
         (ascii-art"██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗
██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝
██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗  
██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝  
╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗
 ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝")
         (username (getenv "USER"))
         (subtitle (format #f "~a" username))
         (first-todo (get-first-todo))
         (options 
          (list 
           (list "Edit" " " "e" "hx")
           (list "Fetch" " " "f" "fastfetch")
           (list "Bash" " " "bs" "bash")
           (list "Guile" " " "g" "guile")
           (list "Dashboard" " " "d" "#dashboard")
           (list "Quit" " " "q" "")))
         (formatted-options (format-options options))
         (welcome-screen (format #f "~a\n~a\n~a\n~a\n" 
                                (center-x ascii-art width)
                                (center-x subtitle width)
                                (center-x first-todo width)
                                (center-x formatted-options width))))
    
    ;; Display initial screen
    (clear-screen)
    (display (center-y welcome-screen height #t))
    
    (let loop ()
      (display ":")
      (let ((input (read-line)))
        (cond
         ((string=? input "q")
          (clear-screen)
          (exit 0))
         ((string=? input "main") 
          (clear-screen)
          (let ((first-todo (get-first-todo)))
            (let ((updated-welcome (format #f "~a\n~a\n~a\n~a\n" 
                                          (center-x ascii-art width)
                                          (center-x subtitle width)
                                          (center-x first-todo width)
                                          (center-x formatted-options width))))
              (display (center-y updated-welcome height #t)))))
         ((string=? input "d")
          (clear-screen)
          (let ((dashboard-text (generate-dashboard)))
            (display dashboard-text)
            (newline)
            (display "Press Enter to return to main menu")
            (read-line)
            (clear-screen)
            (let ((first-todo (get-first-todo)))
              (let ((updated-welcome (format #f "~a\n~a\n~a\n~a\n" 
                                            (center-x ascii-art width)
                                            (center-x subtitle width)
                                            (center-x first-todo width)
                                            (center-x formatted-options width))))
                (display (center-y updated-welcome height #t))))))
         (else
          (let ((matched-option (find (lambda (opt)
                                        (string=? (caddr opt) input))
                                      options)))
            (if matched-option
                (let ((command (cadddr matched-option)))
                  (if (string=? command "#dashboard")
                      (begin
                        (clear-screen)
                        (let ((dashboard-text (generate-dashboard)))
                          (display dashboard-text)
                          (newline)
                          (display "Press Enter to return to main menu")
                          (read-line)
                          (clear-screen)
                          (let ((first-todo (get-first-todo)))
                            (let ((updated-welcome (format #f "~a\n~a\n~a\n~a\n" 
                                                          (center-x ascii-art width)
                                                          (center-x subtitle width)
                                                          (center-x first-todo width)
                                                          (center-x formatted-options width))))
                              (display (center-y updated-welcome height #t))))))
                      (begin
                        (clear-screen)
                        (system command)
                        (clear-screen)
                        (let ((first-todo (get-first-todo)))
                          (let ((updated-welcome (format #f "~a\n~a\n~a\n~a\n" 
                                                        (center-x ascii-art width)
                                                        (center-x subtitle width)
                                                        (center-x first-todo width)
                                                        (center-x formatted-options width))))
                            (display (center-y updated-welcome height #t)))))))
                (loop))))))
      (loop))))

(main)
