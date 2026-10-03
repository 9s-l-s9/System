;;; helpful-conf.el --- -*- lexical-binding: t -*-
(defun sls-helpful-ui-setup ()
  (setq-local sls-ui-title "Help"
              sls-ui-refresh-function #'helpful-update))
(add-hook 'helpful-mode-hook #'sls-helpful-ui-setup)
(provide 'helpful-conf)
