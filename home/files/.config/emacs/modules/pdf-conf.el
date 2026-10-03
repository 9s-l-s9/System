;;; pdf-conf.el --- PDF reader interactions -*- lexical-binding: t -*-
;;; Code:
(use-package pdf-tools
  :if (locate-library "pdf-tools")
  ;; Install the lazy file handler even when use-package defers everything.
  :init (pdf-loader-install))

(defun sls-pdf-ui-setup ()
  (setq-local sls-ui-title "PDF"
              mode-line-process '("" mode-line-position)
              sls-ui-next-function #'pdf-view-next-line-or-next-page
              sls-ui-previous-function #'pdf-view-previous-line-or-previous-page
              sls-ui-actions '(("Next page" . pdf-view-next-page-command)
                               ("Previous page" . pdf-view-previous-page-command)
                               ("Fit page" . pdf-view-fit-page-to-window)
                               ("Fit width" . pdf-view-fit-width-to-window)
                               ("Outline" . pdf-outline))))
(add-hook 'pdf-view-mode-hook #'sls-pdf-ui-setup)

(provide 'pdf-conf)
;;; pdf-conf.el ends here
