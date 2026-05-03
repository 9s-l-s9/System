;;; init.el --- Samuel's Emacs configuration -*- lexical-binding: t -*-
;;; Code:

(add-to-list 'load-path "~/.config/emacs/modules/")
(require 'use-package)
(setq use-package-always-defer t
      use-package-expand-minimally t)

;; ── Core settings ─────────────────────────────────────────────────────────────
(require 'sls-functions)
(require 'general-settings)

;; ── UI ────────────────────────────────────────────────────────────────────────
(require 'general-ui-conf)
(require 'modeline-conf)

(use-package highlight-indent-guides
  :hook (prog-mode . highlight-indent-guides-mode))

;; ── Navigation & editing ──────────────────────────────────────────────────────
(use-package rg
  :commands (rg rg-menu rg-project rg-dwim)
  :config (rg-enable-default-bindings))

(use-package undo-tree
  :init (global-undo-tree-mode))

(with-eval-after-load 'ediff
  (setq ediff-split-window-function 'split-window-horizontally
        ediff-window-setup-function 'ediff-setup-windows-plain))

(require 'focus-conf)
(require 'imenu-list-conf)
(require 'window-conf)

;; ── Completion ────────────────────────────────────────────────────────────────
(require 'corfu-conf)
(require 'cape-conf)
(use-package consult
  :commands (consult-buffer consult-line consult-ripgrep consult-find consult-imenu))
(require 'orderless-conf)
(require 'vertico-conf)
(require 'marginalia-conf)

(use-package all-the-icons-completion
  :hook ((after-init        . all-the-icons-completion-mode)
         (marginalia-mode   . all-the-icons-completion-marginalia-setup)))

;; ── Programming ───────────────────────────────────────────────────────────────
(require 'eglot-conf)
(require 'python-conf)
(require 'dap-conf)
(require 'gptel-conf)

(use-package magit
  :commands (magit-status magit-dispatch magit-file-dispatch))

;; ── Apps ──────────────────────────────────────────────────────────────────────
(require 'dired-conf)
(require 'helpful-conf)
(use-package eat
  :commands (eat eat-other-window))

;; ── Org ───────────────────────────────────────────────────────────────────────
;; (require 'org-conf)
;; (require 'org-modern-conf)
;; (require 'org-babel)
;; (require 'citar-conf)

;; Load at the end
(require 'keybindings-conf)

(unless (and (fboundp 'server-running-p) (server-running-p))
  (server-start))

;;; init.el ends here
