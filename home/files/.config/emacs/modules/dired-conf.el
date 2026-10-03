;;; dired-conf.el --- -*- lexical-binding: t -*-
;;; Code:

;; Open some files in other programs
(setq dired-guess-shell-alist-user
      '(
        ("\\.\\(mp[34]\\|m4a\\|ogg\\|flac\\|webm\\|mkv\\)" "mpv" "xdg-open")
	))

(setq dired-listing-switches "-alhU")

;; Core Dired faces provide the same quiet hierarchy as the other views.
;; File types remain visible through names and listing details.

(defun sls-dired-sidebar-show (directory)
  "Show DIRECTORY in an independent Dired buffer in the sidebar."
  (require 'dired)
  (let ((buffer (get-buffer-create "*Dired Sidebar*")))
    (with-current-buffer buffer
      (setq default-directory (file-name-as-directory (expand-file-name directory)))
      (dired-mode default-directory dired-listing-switches)
      (setq-local sls-side-panel-p t)
      (dired-readin)
      ;; Ordinary `dired' visits must never reuse this dedicated panel.
      (setq dired-buffers (cl-delete buffer dired-buffers :key #'cdr :test #'eq))
      (goto-char (point-min))
      (dired-initial-position default-directory)
      (dired-hide-details-mode 1))
    (sls-side-panel-show buffer)))

(defun sls-dired-sidebar-toggle ()
  "Toggle the Dired sidebar for the current directory."
  (interactive)
  (let ((window (sls-side-panel-window)))
    (if (and window (with-current-buffer (window-buffer window)
                      (and (derived-mode-p 'dired-mode) sls-side-panel-p)))
        (delete-window window)
      (sls-dired-sidebar-show default-directory))))

(defun sls-dired-open ()
  "Visit a directory in the panel or a file in the main window."
  (interactive)
  (let ((file (dired-get-file-for-visit)))
    (cond ((and sls-side-panel-p (file-directory-p file))
           (sls-dired-sidebar-show file))
          (sls-side-panel-p (sls-panel-visit-buffer (find-file-noselect file)))
          (t (dired-find-file)))))

(defun sls-dired-parent ()
  "Go up a directory, retaining the sidebar when used there."
  (interactive)
  (if sls-side-panel-p
      (sls-dired-sidebar-show (file-name-directory (directory-file-name default-directory)))
    (dired-up-directory)))

(defun sls-dired-ui-setup ()
  (setq-local sls-ui-title "Files"
              sls-ui-open-function #'sls-dired-open
              sls-ui-next-function #'dired-next-line
              sls-ui-previous-function #'dired-previous-line
              sls-ui-actions '(("Parent directory" . sls-dired-parent)
                               ("Mark file" . dired-mark)
                               ("Unmark file" . dired-unmark)
                               ("Copy files…" . dired-do-copy)
                               ("Rename files…" . dired-do-rename)
                               ("Sort…" . sls-dired-sort)
                               ("Toggle details" . dired-hide-details-mode))))
(add-hook 'dired-mode-hook #'sls-dired-ui-setup)

(provide 'dired-conf)
;;; dired-conf.el ends here
