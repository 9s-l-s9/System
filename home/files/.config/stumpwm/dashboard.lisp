(defun show-todos (todo-file)
  "Show open TODOs from org file at TODO-FILE path. Returns a string of TODOs or 'No open TODOs' message."
  (let* ((todos (with-open-file (stream todo-file)
                  (loop for line = (read-line stream nil nil)
                        while line
                        ;; First trim leading/trailing whitespace
                        for cleaned-line = (string-trim " " line)
                        ;; Check if line starts with any number of asterisks followed by TODO
                        when (and (> (length cleaned-line) 6)
                                (char= (char cleaned-line 0) #\*)
                                ;; Find position after asterisks
                                (let* ((content-start (position-if-not 
                                                     (lambda (c) (char= c #\*)) 
                                                     cleaned-line))
                                      (content (string-trim " " 
                                                          (subseq cleaned-line content-start))))
                                  (and content-start
                                       (> (length content) 4)
                                       (string= "TODO" (subseq content 0 4)))))
                        ;; Collect the actual todo text, removing asterisks and TODO
                        collect (let* ((content-start (position-if-not 
                                                     (lambda (c) (char= c #\*)) 
                                                     cleaned-line))
                                     (content (string-trim " " 
                                                         (subseq cleaned-line content-start))))
                                (string-trim " " (subseq content 4))))))
         (todo-string (if todos
                         (format nil "~%~{~A~^~%~}" todos)
                         "No open TODOs")))
    todo-string))


(defun get-uncommitted-changes ()
  "Returns a string listing projects with uncommitted changes."
  (let ((output (run-shell-command "~/.config/stumpwm/check-uncommitted.sh" t)))
    (if (string= output "")
        "All projects are clean!"
        output)))

(defun get-downloads ()
  "Returns a string listing files in the Downloads directory."
  (let ((files (directory "/home/samuel/Downloads/*.*")))
    (if (null files)
        "Download directory is clean!"
        (format nil "~{~A~^~%~}" 
                (mapcar #'(lambda (path) 
                           (namestring path)) 
                        files)))))

(defun get-random-file (directory)
  "Returns a random file from the specified directory"
  (let* ((files (directory (concatenate 'string directory "/*.*")))
         (file-count (length files)))
    (if (> file-count 0)
        (nth (random file-count) files)
        nil)))

(defun format-file-content (file)
  "Formats the content of a file for display"
  (handler-case
      (with-open-file (stream file)
        (let ((content (make-string (file-length stream))))
          (read-sequence content stream)
          (format nil "=== Random Quote: ~A ===~%~A" file content)))
    (error (e)
      (format nil "Error reading file: ~A" e))))

(defcommand dashboard () ()
  "Displays comprehensive dashboard including TODOs, git status, downloads, and a random file"
  (let* ((org-files '("/home/samuel/Projects/WorkingMemory/wm-t450s.org"
                      "/home/samuel/Projects/WorkingMemory/wm-x1.org"
                      "/home/samuel/Projects/WorkingMemory/wm-palma.org"))
         (random-file (get-random-file "/home/samuel/Projects/Reflections/Quotes/"))
         (todos-section (format nil "=== TODOs ===~%~{~A~%~%~}"
                                (loop for file in org-files
                                      collect (format nil "--- ~A ---~%~A"
                                                      (car (last (split-string file "/")))
                                                      (handler-case
                                                          (show-todos file)
                                                        (error (e)
                                                          (format nil "Error reading file: ~A" e)))))))
         (git-section (format nil "=== Git Status ===~%~A" 
                              (get-uncommitted-changes)))
         (downloads-section (format nil "=== Downloads ===~%~A"
                                    (get-downloads)))
         (random-file-section (if random-file
                                  (format-file-content random-file)
                                  "=== Random File ===~%No files found"))
         (dashboard-text (format nil "~A~%~%~A~%~%~A~%~%~A"
                                 random-file-section
                                 todos-section
                                 git-section
                                 downloads-section
                                 )))
    (message "~A" dashboard-text)))