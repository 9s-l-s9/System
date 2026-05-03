;;; cape-conf.el --- -*- lexical-binding: t -*-
(require 'cape)

;; Enable Corfu completion UI
;; See the Corfu README for more configuration tips.

(use-package cape
  :init
  ;; Append (4th arg `t`) so these stay BEHIND any mode-/lsp-provided capf
  ;; (e.g. eglot-completion-at-point), making cape a fallback rather than
  ;; shadowing semantic completions with dabbrev/keyword matches.
  (dolist (mode '(text-mode-hook prog-mode-hook conf-mode-hook))
    (add-hook mode
              (lambda ()
                (add-to-list 'completion-at-point-functions #'cape-file       t)
                (add-to-list 'completion-at-point-functions #'cape-tex        t)
                (add-to-list 'completion-at-point-functions #'cape-dabbrev    t)
                (add-to-list 'completion-at-point-functions #'cape-keyword    t)
                (add-to-list 'completion-at-point-functions #'cape-elisp-block t)
                (add-to-list 'completion-at-point-functions #'cape-elisp-symbol t))))))

(provide 'cape-conf)
