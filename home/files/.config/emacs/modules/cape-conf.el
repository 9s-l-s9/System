;;; cape-conf.el --- -*- lexical-binding: t -*-
;; cape functions are all autoloaded (see cape-autoloads.el), so this file
;; never needs to `require' cape eagerly.

;; Enable Corfu completion UI
;; See the Corfu README for more configuration tips.

;; Append (4th arg `t`) so these stay BEHIND any mode-/lsp-provided capf
;; (e.g. eglot-completion-at-point), making cape a fallback rather than
;; shadowing semantic completions with dabbrev/keyword matches.
(dolist (mode '(text-mode-hook prog-mode-hook conf-mode-hook))
  (add-hook mode
            (lambda ()
              (add-to-list 'completion-at-point-functions #'cape-file    t)
              (add-to-list 'completion-at-point-functions #'cape-dabbrev t)
              (add-to-list 'completion-at-point-functions #'cape-keyword t))))

;; cape-tex only makes sense where TeX-style macro entry happens.
(dolist (mode '(text-mode-hook org-mode-hook))
  (add-hook mode
            (lambda ()
              (add-to-list 'completion-at-point-functions #'cape-tex t))))

;; cape-elisp-* only makes sense in Elisp buffers/REPLs.
(dolist (mode '(emacs-lisp-mode-hook ielm-mode-hook lisp-interaction-mode-hook))
  (add-hook mode
            (lambda ()
              (add-to-list 'completion-at-point-functions #'cape-elisp-block  t)
              (add-to-list 'completion-at-point-functions #'cape-elisp-symbol t))))

(provide 'cape-conf)
