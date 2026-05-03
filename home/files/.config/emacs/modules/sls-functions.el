;;; sls-functions.el --- Personal utility functions -*- lexical-binding: t -*-
;;; Code:

(defun sls-dired-sort ()
  "Sort dired listing interactively."
  (interactive)
  (let* ((choice (completing-read "Sort by: " '("name" "date" "size" "dir")))
         (arg (pcase choice
                ("name" "-Al --si --time-style long-iso")
                ("date" "-Al --si --time-style long-iso -t")
                ("size" "-Al --si --time-style long-iso -S")
                ("dir"  "-Al --si --time-style long-iso --group-directories-first")
                (_ (error "Unknown sort key: %s" choice)))))
    (dired-sort-other arg)))

(defun sls-reload-init-file ()
  "Reload init.el without restarting Emacs."
  (interactive)
  (server-force-delete)
  (load-file user-init-file))

(defun sls--find-file-make-parent-maybe (filename &optional _wildcards)
  "Offer to create the parent directory of FILENAME when missing."
  (let ((dir (and (stringp filename) (file-name-directory filename))))
    (when (and dir
               (not (file-exists-p dir))
               (y-or-n-p (format "Create parent directory %s? " dir)))
      (make-directory dir t))))

(advice-add 'find-file :before #'sls--find-file-make-parent-maybe)

(defun sls-copy-file-path ()
  "Copy the current file path (or dired directory) to the clipboard."
  (interactive)
  (let ((filename (if (eq major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (when filename
      (with-temp-buffer
        (insert filename)
        (clipboard-kill-region (point-min) (point-max)))
      (message "%s" filename))))

(defun sls-new-entry-pkb (name)
  "Create a new entry NAME in the personal knowledge base."
  (interactive "sEntry name: ")
  (let* ((base-dir "~/Projects/personal-knowledge-base/pages/")
         (dir-path (expand-file-name (upcase name) base-dir))
         (file-path (expand-file-name (concat name ".org") dir-path)))
    (make-directory dir-path t)
    (find-file file-path)))

(defun sls-export-org-to-html-and-pdf ()
  "Export current Org buffer to HTML and PDF."
  (interactive)
  (when (derived-mode-p 'org-mode)
    (org-html-export-to-html)
    (org-latex-export-to-pdf)))

;; Recent files as a navigable buffer
;; Forward declaration so byte-compiling `sls-recentf-mode' is happy.
(declare-function sls-recentf--refresh "sls-functions")
(declare-function sls-recentf--open    "sls-functions")

(defun sls-recentf--refresh (&rest _)
  "Populate the *Recent Files* buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (dolist (file recentf-list)
      (let ((name (file-name-nondirectory file))
            (dir  (abbreviate-file-name (file-name-directory file))))
        (insert (propertize name 'face 'link 'sls-path file))
        (insert (propertize (concat "  " dir) 'face 'shadow))
        (insert "\n")))
    (goto-char (point-min))))

(defun sls-recentf--open ()
  "Open the file on the current line."
  (interactive)
  (let ((path (get-text-property (point) 'sls-path)))
    (if path
        (find-file path)
      (message "No file at point"))))

(define-derived-mode sls-recentf-mode special-mode "RecentF"
  "Browse recent files in a dedicated buffer."
  (setq-local revert-buffer-function #'sls-recentf--refresh)
  (define-key sls-recentf-mode-map (kbd "RET") #'sls-recentf--open)
  (define-key sls-recentf-mode-map (kbd "j") #'next-line)
  (define-key sls-recentf-mode-map (kbd "k") #'previous-line))

(defun sls-recentf-open ()
  "Open recent files in a side panel buffer."
  (interactive)
  (recentf-mode 1)
  (let ((buf (get-buffer-create "*Recent Files*")))
    (with-current-buffer buf
      (unless (derived-mode-p 'sls-recentf-mode)
        (sls-recentf-mode))
      (sls-recentf--refresh))
    (select-window (display-buffer buf))))

;; Dired as a right-side panel
(defun sls-dired-sidebar-toggle ()
  "Toggle a Dired sidebar for the current project/directory."
  (interactive)
  (let* ((dir (or (when (buffer-file-name)
                    (file-name-directory (buffer-file-name)))
                  default-directory))
         (buf-name "*Dired Sidebar*")
         (existing (get-buffer buf-name))
         (win (and existing (get-buffer-window existing))))
    (if win
        (delete-window win)
      (let ((buf (dired-noselect dir)))
        (with-current-buffer buf
          (rename-buffer buf-name t))
        (select-window (display-buffer buf))))))

(provide 'sls-functions)
;;; sls-functions.el ends here
