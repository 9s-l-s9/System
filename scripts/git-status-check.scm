#!/usr/bin/env guile
!#

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 ftw))

;; Base directory to search for git projects
(define base-dir "/home/samuel/Projects")

;; Function to check if a git repository has uncommitted changes
(define (has-uncommitted-changes? repo-dir)
  (let* ((command (string-append "git -C " repo-dir " status --porcelain"))
         (port (open-input-pipe command))
         (output (read-string port)))
    (close-pipe port)
    (not (string-null? output))))

;; Function to check if a directory is a git repository
(define (is-git-repo? dir)
  (let ((git-dir (string-append dir "/.git")))
    (and (file-exists? git-dir) 
         (file-is-directory? git-dir))))

;; Process all git repositories under the base directory
(define (process-directories)
  (ftw base-dir
       (lambda (file stat flag)
         (when (and (eq? flag 'directory)
                   (is-git-repo? file)
                   (has-uncommitted-changes? file))
           (format #t "Uncommitted changes in: ~a~%" file))
         #t)))

(process-directories)
