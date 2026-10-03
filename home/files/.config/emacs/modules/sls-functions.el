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
  "Re-read init.el and its local configuration modules without restarting.
Startup-only settings in early-init.el still require a new Emacs session."
  (interactive)
  (unless (and user-init-file (file-readable-p user-init-file))
    (user-error "No readable init file is associated with this session"))
  (load-file user-init-file)
  (message "Configuration modules reloaded"))

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

;; Quick-capture to the shared working-memory inbox.
;; Lands in the same file and format as the StumpWM `add-todo' command
;; (scripts/add-todo.scm): "* TODO YYYY-MM-DD text", so captures from the
;; window manager and from Emacs converge on one inbox.
(defcustom sls-working-memory-file "~/Projects/WorkingMemory/wm.org"
  "Org file used as the shared TODO inbox."
  :type 'file
  :group 'sls)

(defun sls-capture-todo (text)
  "Append TEXT as a dated TODO to `sls-working-memory-file'."
  (interactive "sTODO: ")
  (let ((file (expand-file-name sls-working-memory-file)))
    (with-temp-buffer
      (insert (format "* TODO %s %s\n\n"
                      (format-time-string "%Y-%m-%d") text))
      (append-to-file (point-min) (point-max) file))
    (message "Captured to %s: %s" (file-name-nondirectory file) text)))

;; Command center: jump to any tracked file in the System config repo.
(defun sls-config-jump ()
  "Open a tracked file from the System configuration repository."
  (interactive)
  (let* ((root (expand-file-name "~/Projects/System/"))
         (files (and (file-directory-p root)
                     (split-string
                      (shell-command-to-string
                       (format "git -C %s ls-files"
                               (shell-quote-argument root)))
                      "\n" t))))
    (if files
        (find-file (expand-file-name
                    (completing-read "Config file: " files nil t) root))
      (user-error "No git-tracked files under %s" root))))

(provide 'sls-functions)
;;; sls-functions.el ends here
