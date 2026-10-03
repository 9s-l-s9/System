;;; recentf-conf.el --- Recent files panel -*- lexical-binding: t -*-
;;; Code:
(require 'recentf)
(require 'tabulated-list)

(define-derived-mode sls-recentf-mode tabulated-list-mode "Recent files"
  "Browse recent files; activate a row to open it in the main window."
  (setq-local sls-ui-title "Recent files"
              sls-ui-open-function #'sls-recentf-open-file
              tabulated-list-format [("File" 24 t) ("Directory" 0 t)]
              tabulated-list-padding 0
              tabulated-list-entries #'sls-recentf-entries)
  (tabulated-list-init-header))

(defun sls-recentf-entries ()
  "Return recent files as table rows."
  (mapcar (lambda (file)
            (list file (vector (file-name-nondirectory file)
                               (abbreviate-file-name (file-name-directory file)))))
          recentf-list))

(defun sls-recentf-open-file ()
  "Open the file on this row in the main window."
  (interactive)
  (let ((file (tabulated-list-get-id)))
    (unless file (user-error "No file on this row"))
    (sls-panel-visit-buffer (find-file-noselect file))))

(defun sls-recentf-open ()
  "Show recent files in the sidebar."
  (interactive)
  (recentf-mode 1)
  (let ((buffer (get-buffer-create "*Recent Files*")))
    (with-current-buffer buffer
      (unless (derived-mode-p 'sls-recentf-mode) (sls-recentf-mode))
      (tabulated-list-print t))
    (sls-side-panel-show buffer)))

(provide 'recentf-conf)
;;; recentf-conf.el ends here
