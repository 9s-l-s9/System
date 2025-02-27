(require 'focus)

;; Set modes on when to start focus mode and what to thing to focus on
(add-hook 'org-mode-hook #'focus-mode)

(add-hook 'python-mode-hook #'focus-mode)
(add-to-list 'focus-mode-to-thing '(python-mode . paragraph))

(add-hook 'scheme-mode-hook #'focus-mode)
(add-to-list 'focus-mode-to-thing '(scheme-mode . list))

(provide 'focus-conf)
