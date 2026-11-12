;;; cape-conf.el --- -*- lexical-binding: t -*-
;; dabbrev scanning every buffer on each popup is the expensive part.
(setq cape-dabbrev-check-other-buffers 'some)

;; cape functions are all autoloaded (see cape-autoloads.el), so this file
;; never needs to `require' cape eagerly.

;; Enable Corfu completion UI
;; See the Corfu README for more configuration tips.

;; Buffer-local hooks at depth 90 stay BEHIND mode-/lsp-provided capf
;; (e.g. eglot-completion-at-point), making cape a fallback rather than
;; shadowing semantic completions with dabbrev/keyword matches.
(dolist (mode '(text-mode-hook prog-mode-hook conf-mode-hook))
  (add-hook mode
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-file    90 t)
              (add-hook 'completion-at-point-functions #'cape-dabbrev 90 t)
              (add-hook 'completion-at-point-functions #'cape-keyword 90 t))))

;; cape-tex only makes sense where TeX-style macro entry happens.
(dolist (mode '(text-mode-hook org-mode-hook))
  (add-hook mode
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-tex 90 t))))

;; cape-elisp-* only makes sense in Elisp buffers/REPLs.
(dolist (mode '(emacs-lisp-mode-hook ielm-mode-hook lisp-interaction-mode-hook))
  (add-hook mode
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-elisp-block  90 t)
              (add-hook 'completion-at-point-functions #'cape-elisp-symbol 90 t))))

(provide 'cape-conf)
