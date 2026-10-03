;;; eat-conf.el --- Terminal input follows Meow state -*- lexical-binding: t -*-
;;; Code:
(use-package eat :commands (eat eat-other-window))

(defun sls-eat-input ()
  "Send typed keys to the terminal when entering Meow insert."
  (when (and (derived-mode-p 'eat-mode) (bound-and-true-p eat-terminal))
    (eat-semi-char-mode)))

(defun sls-eat-browse ()
  "Use Emacs navigation in terminal scrollback outside insert state."
  (when (derived-mode-p 'eat-mode) (eat-emacs-mode)))

(defun sls-eat-started (&rest _)
  "Synchronize a newly started terminal with Meow's current state."
  (when (bound-and-true-p meow-mode)
    (if (bound-and-true-p meow-insert-mode) (sls-eat-input) (sls-eat-browse))))

(defun sls-eat-ui-setup ()
  (setq-local sls-ui-title "Terminal"
              sls-ui-actions '(("Type into terminal" . meow-insert)
                               ("Browse scrollback" . meow-insert-exit)))
  (add-hook 'meow-insert-enter-hook #'sls-eat-input nil t)
  (add-hook 'meow-insert-exit-hook #'sls-eat-browse nil t))
(add-hook 'eat-mode-hook #'sls-eat-ui-setup)
(add-hook 'eat-exec-hook #'sls-eat-started)

(provide 'eat-conf)
;;; eat-conf.el ends here
