;;; magit-conf.el --- Git application interactions -*- lexical-binding: t -*-
;;; Code:
(use-package magit :commands (magit-status magit-dispatch magit-file-dispatch))
(defun sls-magit-ui-setup ()
  (setq-local sls-ui-title "Git"
              sls-ui-refresh-function #'magit-refresh
              sls-ui-actions '(("Git commands…" . magit-dispatch)
                               ("Stage change" . magit-stage)
                               ("Unstage change" . magit-unstage)
                               ("Commit…" . magit-commit)
                               ("Diff…" . magit-diff)
                               ("Log…" . magit-log))))
(add-hook 'magit-mode-hook #'sls-magit-ui-setup)
(provide 'magit-conf)
;;; magit-conf.el ends here
