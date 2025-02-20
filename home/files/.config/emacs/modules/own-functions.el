(provide 'own-functions)
;; add custom compilation command for C++ with debugging info
(defun sls-reload-init-file ()
  (interactive)
  (server-force-delete)
  (load-file user-init-file))

(defun sls-compile-cpp-debug ()
  (interactive)
  (compile (format "g++ -std=c++17 -Wshadow -Wall -o %s %s -g -fsanitize=address -fsanitize=undefined -D_GLIBCXX_DEBUG"
                   "main"                                ; output file name is always "main"
                   (buffer-file-name))))                 ; input file name is the full path to the current buffer

(defun sls-new-entry-pkb (x)
  "Interactively create a directory and file in ~/Projects/, and commit the changes."
  (interactive "sEnter the name: ") ; prompt the user for the name x
  (let* ((base-dir "~/Projects/personal-knowledge-base/pages/")
         (dir-name (upcase x))
         (file-name (concat x ".org"))
         (full-dir-path (expand-file-name dir-name base-dir))
         (full-file-path (expand-file-name file-name full-dir-path)))
    ;; Create directory
    (make-directory full-dir-path t)
    ;; Create file
    (write-region "" nil full-file-path)
    (find-file full-file-path)
))

(defun sls-export-org-to-html-and-pdf ()
  "Export the current Org buffer to both HTML and PDF."
  (interactive)
  ;; Check if the current buffer is an Org mode buffer
  (if (eq major-mode 'org-mode)
      (progn
        ;; Export to HTML
        (org-html-export-to-html)
        ;; Export to PDF
        (org-latex-export-to-pdf))
    (message "This is not an Org mode buffer.")))



(defun sls-dired-sort ()
  (interactive)
  (let (-sort-by -arg)
    (setq -sort-by (ido-completing-read "Sort by:" '( "date" "size" "name" "dir")))
    (cond
     ((equal -sort-by "name") (setq -arg "-Al --si --time-style long-iso "))
     ((equal -sort-by "date") (setq -arg "-Al --si --time-style long-iso -t"))
     ((equal -sort-by "size") (setq -arg "-Al --si --time-style long-iso -S"))
     ((equal -sort-by "dir") (setq -arg "-Al --si --time-style long-iso --group-directories-first"))
     (t (error "logic error 09535" )))
    (dired-sort-other -arg )))

(defun sls-reload-init-file ()
  (interactive)
  (server-force-delete)
  (load-file user-init-file))

(defadvice find-file (before make-directory-maybe (filename &optional wildcards) activate)
  "Create parent directory if not exists while visiting file."
  (unless (file-exists-p filename)
    (let ((dir (file-name-directory filename)))
      (unless (file-exists-p dir)
        (make-directory dir t)))))

(defun sls-copy-file-path ()
  "Put the current file name on the clipboard"
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (when filename
      (with-temp-buffer
        (insert filename)
        (clipboard-kill-region (point-min) (point-max)))
      (message filename))))

(defun sls-setup-cp-folder-revised (name)
  "Revised function to set up a folder for a competitive programming challenge."
  (interactive "sEnter challenge name: ")

  ;; Define the base directory
  (let* ((base-dir (concat "~/Projects/comp-programming/" (file-name-as-directory name)))
         ;; Define cpp-file in the same let* block to have it accessible later
         (cpp-file (concat base-dir name ".cpp")))

    ;; Create the directory
    (make-directory base-dir t)

    ;; Create the .cpp file inside the directory
    (write-region "" nil cpp-file)
    (message "Created file: %s" cpp-file)

    ;; Create the input and output test files
    (dotimes (i 3)
      (let ((test-num (1+ i)))
        (write-region "" nil (concat base-dir (format "test%d_input.txt" test-num)))
        (message "Created file: %s/test%d_input.txt" base-dir test-num)
        (write-region "" nil (concat base-dir (format "test%d_output.txt" test-num)))
        (message "Created file: %s/test%d_output.txt" base-dir test-num)))

    ;; Open the .cpp file
    (find-file cpp-file)
    (message "Setup complete for %s!" name)))

(defun sls-format-names-for-cards (input-string)
  "Format each name in INPUT-STRING as ** {{cards [[name]] }}."
  (let ((names (split-string input-string " " t))
        (formatted-names '()))
    (dolist (name names)
      (push (format "** {{cards [[%s]] }}" name) formatted-names))
    (mapconcat 'identity (reverse formatted-names) "\n")))
