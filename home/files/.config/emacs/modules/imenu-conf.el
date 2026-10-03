;;; imenu-conf.el --- Built-in Imenu in a side panel -*- lexical-binding: t -*-
;;; Code:
(require 'imenu)
(require 'tabulated-list)

(defvar-local sls-imenu-source nil)
(defvar-local sls-imenu-tick nil)

(define-derived-mode sls-imenu-mode tabulated-list-mode "Outline"
  "Browse the source buffer's Imenu index."
  (setq-local sls-ui-title "Outline"
              sls-ui-open-function #'sls-imenu-open-item
              sls-ui-refresh-function #'sls-imenu-refresh
              tabulated-list-format [("Symbol" 0 nil)]
              tabulated-list-padding 0)
  (tabulated-list-init-header))

(defun sls-imenu-rows (index &optional prefix)
  "Flatten INDEX while preserving groups and Imenu's extended entries."
  (cl-mapcan
   (lambda (entry)
     (cond ((equal (car entry) "*Rescan*") nil)
           ((imenu--subalist-p entry)
            (sls-imenu-rows (cdr entry) (concat prefix (car entry) " / ")))
           (t (list (list entry (vector (concat prefix (car entry))))))))
   index))

(defun sls-imenu-refresh ()
  "Rescan the source buffer and refresh the outline."
  (interactive)
  (unless (buffer-live-p sls-imenu-source) (user-error "Outline source was closed"))
  (let ((source sls-imenu-source))
    (setq tabulated-list-entries
          (with-current-buffer source
            (setq imenu--index-alist nil)
            (sls-imenu-rows (imenu--make-index-alist t))))
    (setq sls-imenu-tick (buffer-chars-modified-tick source))
    (tabulated-list-print t)))

(defun sls-imenu-open-item ()
  "Activate the Imenu entry using its source mode's own jump function."
  (interactive)
  (unless (buffer-live-p sls-imenu-source) (user-error "Outline source was closed"))
  (unless (= sls-imenu-tick (buffer-chars-modified-tick sls-imenu-source))
    (sls-imenu-refresh)
    (user-error "Source changed; outline refreshed, select the symbol again"))
  (let ((entry (tabulated-list-get-id)) (source sls-imenu-source))
    (unless entry (user-error "No symbol on this row"))
    (sls-panel-visit-buffer source)
    (imenu entry)))

(defun sls-imenu-toggle ()
  "Toggle an outline for the current main buffer."
  (interactive)
  (let ((window (sls-side-panel-window))
        (source (window-buffer (sls-main-window))))
    (if (and window (with-current-buffer (window-buffer window)
                      (and (derived-mode-p 'sls-imenu-mode)
                           (eq sls-imenu-source source))))
        (delete-window window)
      (let ((buffer (get-buffer-create "*Outline*")))
        (with-current-buffer buffer
          (unless (derived-mode-p 'sls-imenu-mode) (sls-imenu-mode))
          (setq sls-imenu-source source)
          (sls-imenu-refresh))
        (sls-side-panel-show buffer)))))

(provide 'imenu-conf)
;;; imenu-conf.el ends here
