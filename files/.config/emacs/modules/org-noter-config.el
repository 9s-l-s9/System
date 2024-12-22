(provide 'org-noter-config)

;;(add-to-list 'load-path "~/Projects/org-noter")
(require 'org-noter)

;; Org-noter
  (setq org-noter-doc-split-fraction '(0.7 . 0.7)
        org-noter-hide-other nil
        org-noter-always-create-frame nil
	)


(defun my-org-noter-insert-heading-hook ()
  (select-window (frame-first-window)))

(add-hook 'org-noter-insert-heading-hook 'my-org-noter-insert-heading-hook)
