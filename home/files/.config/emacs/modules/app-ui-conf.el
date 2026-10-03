;;; app-ui-conf.el --- Common application interactions -*- lexical-binding: t -*-
;;; Code:
(require 'cl-lib)
(require 'subr-x)
(defvar meow-normal-mode)
(defvar meow-motion-mode)
(defvar meow-keypad-mode)
(defvar meow-valsi-mode)

(defvar-local sls-ui-title nil "Short role label for this application buffer.")
(defvar-local sls-ui-actions nil "Alist of named application commands.")
(defvar-local sls-ui-open-function nil)
(defvar-local sls-ui-refresh-function nil)
(defvar-local sls-ui-next-function nil)
(defvar-local sls-ui-previous-function nil)

(defun sls-ui-view-layout ()
  "Keep editor line numbers out of application views."
  (when (and (bound-and-true-p display-line-numbers-mode)
             (or sls-ui-title
                 (derived-mode-p 'special-mode 'help-mode 'Info-mode
                                 'dired-mode 'ibuffer-mode 'bookmark-bmenu-mode)))
    (display-line-numbers-mode -1)))
;; Run after global-display-line-numbers-mode has initialized the new buffer.
(add-hook 'after-change-major-mode-hook #'sls-ui-view-layout 90)
(add-hook 'display-line-numbers-mode-hook #'sls-ui-view-layout)

(defun sls-ui-next ()
  "Move down using application navigation or Meow's motion."
  (interactive)
  (call-interactively (or sls-ui-next-function #'meow-next)))

(defun sls-ui-previous ()
  "Move up using application navigation or Meow's motion."
  (interactive)
  (call-interactively (or sls-ui-previous-function #'meow-prev)))

(defun sls-ui-native-command (keys)
  "Resolve KEYS without Meow's navigation maps."
  (let ((meow-normal-mode nil) (meow-motion-mode nil)
        (meow-keypad-mode nil) (meow-valsi-mode nil))
    (key-binding keys t)))

(defun sls-ui-native-key ()
  "Read and run a native application key, including prefix sequences."
  (interactive)
  (let* ((keys nil)
         (command
          (let ((meow-normal-mode nil) (meow-motion-mode nil)
                (meow-keypad-mode nil) (meow-valsi-mode nil))
            (setq keys (read-key-sequence "Application key: "))
            (key-binding keys t))))
    (unless (commandp command)
      (user-error "No command on %s" (key-description keys)))
    (call-interactively command)))

(defun sls-ui-open ()
  "Activate the item at point using the application's own command."
  (interactive)
  (let ((command (or sls-ui-open-function (sls-ui-native-command (kbd "RET")))))
    (unless (and (commandp command)
                 (not (memq command '(sls-ui-open newline newline-and-indent))))
      (user-error "No item to open here"))
    (call-interactively command)))

(defun sls-ui-refresh ()
  "Refresh this view, preserving confirmation for unsaved file edits."
  (interactive)
  (call-interactively (or sls-ui-refresh-function #'revert-buffer)))

(defun sls-ui-quit ()
  "Close a view using its native cleanup when available."
  (interactive)
  (let ((command (sls-ui-native-command (kbd "q"))))
    (if (and (not buffer-file-name) (commandp command)
             (not (memq command '(self-insert-command meow-quit sls-ui-quit))))
        (call-interactively command)
      (quit-window))))

(defun sls-ui-actions ()
  "Choose a named action for this buffer using built-in completion."
  (interactive)
  (let* ((actions
          (append sls-ui-actions
                  '(("Open item" . sls-ui-open)
                    ("Refresh view" . sls-ui-refresh)
                    ("Close view" . sls-ui-quit)
                    ("Put this buffer in sidebar" . sls-side-panel-pin)
                    ("Move sidebar buffer to main window" . sls-side-panel-pop-out)
                    ("Native application key…" . sls-ui-native-key)
                    ("Describe this mode" . describe-mode))))
         (available (cl-remove-if-not (lambda (entry) (commandp (cdr entry))) actions))
         (choice (completing-read (format "%s action: " (or sls-ui-title mode-name))
                                  available nil t)))
    (call-interactively (cdr (assoc choice available)))))

(provide 'app-ui-conf)
;;; app-ui-conf.el ends here
