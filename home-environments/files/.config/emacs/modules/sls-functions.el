(provide 'sls-functions)

(defun sls-reload-init-file ()
  (interactive)
  (server-force-delete)
  (load-file user-init-file))

(defun sls-new-entry-pkb (x)
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

(defun sls-format-names-for-cards (input-string)
  "Format each name in INPUT-STRING as ** {{cards [[name]] }}."
  (let ((names (split-string input-string " " t))
        (formatted-names '()))
    (dolist (name names)
      (push (format "** {{cards [[%s]] }}" name) formatted-names))
    (mapconcat 'identity (reverse formatted-names) "\n")))
