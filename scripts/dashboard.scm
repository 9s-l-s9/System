#!/usr/bin/env guile
!#

(use-modules (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 string-fun)
             (ice-9 ftw)
             (ice-9 popen)
             (srfi srfi-1))

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
    todo-string))

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

;; Dashboard function combining everything
(define (dashboard)
  "Displays comprehensive dashboard including TODOs, git status, and downloads"
  (let* ((org-files '("/home/samuel/Projects/WorkingMemory/wm-T450s.org"
                       "/home/samuel/Projects/WorkingMemory/wm-X1.org"
                       "/home/samuel/Projects/WorkingMemory/wm-palma.org"))
         (todos-section 
          (string-append "=== TODOs ===\n"
                         (string-join 
                          (map (lambda (file)
                                (let ((filename (last (string-split file #\/))))
                                  (string-append "--- " filename " ---\n"
                                                (catch #t
                                                       (lambda () (show-todos file))
                                                       (lambda (key . args)
                                                         (string-append "Error reading file: " 
                                                                       (symbol->string key)))))))
                               org-files)
                          "\n\n")))
         (git-section 
          (string-append "=== Git Status ===\n" (get-uncommitted-changes)))
         (downloads-section 
          (string-append "=== Downloads ===\n" (get-downloads)))
         (dashboard-text 
          (string-append todos-section "\n\n" git-section "\n\n" downloads-section)))
    (display dashboard-text)
    (newline)))

;; Execute the dashboard when script is run
(dashboard)
