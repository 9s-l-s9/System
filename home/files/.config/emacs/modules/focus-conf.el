;;; focus-conf.el --- -*- lexical-binding: t -*-
;; `focus-mode' is autoloaded, so hooking it here doesn't force focus.el to
;; load eagerly; it loads the first time one of these hooks fires.

;; Set modes on when to start focus mode and what to thing to focus on
(add-hook 'org-mode-hook #'focus-mode)
(add-hook 'python-mode-hook #'focus-mode)
(add-hook 'python-ts-mode-hook #'focus-mode)
(add-hook 'scheme-mode-hook #'focus-mode)

;; `focus-mode-to-thing' is defined in focus.el itself, so customizing it
;; must wait until the package is actually loaded.
(with-eval-after-load 'focus
  (add-to-list 'focus-mode-to-thing '(python-mode . paragraph))
  (add-to-list 'focus-mode-to-thing '(python-ts-mode . paragraph))
  (add-to-list 'focus-mode-to-thing '(scheme-mode . list)))

(provide 'focus-conf)
