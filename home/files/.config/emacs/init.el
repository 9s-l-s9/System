;;; init.el --- Samuel's Emacs configuration -*- lexical-binding: t -*-
;;; Code:

(add-to-list 'load-path "~/.config/emacs/modules/")
(require 'use-package)

;; ── Core settings ─────────────────────────────────────────────────────────────
(require 'sls-functions)
(require 'general-settings)

;; ── UI ────────────────────────────────────────────────────────────────────────
(require 'general-ui-config)
(require 'modeline-config)

;; ── Navigation & editing ──────────────────────────────────────────────────────
(require 'rg)
(rg-enable-default-bindings)

(require 'undo-tree)
(global-undo-tree-mode)

(setq ediff-split-window-function 'split-window-horizontally
      ediff-window-setup-function 'ediff-setup-windows-plain)

(require 'focus-conf)
(require 'imenu-list)
(require 'window-conf)

;; ── Completion ────────────────────────────────────────────────────────────────
(require 'corfu-conf)
(require 'cape-conf)
(require 'consult)
(require 'orderless-conf)
(require 'vertico-conf)
(require 'marginalia-conf)

(all-the-icons-completion-mode)
(add-hook 'marginalia-mode-hook #'all-the-icons-completion-marginalia-setup)

;; ── Programming ───────────────────────────────────────────────────────────────
(require 'highlight-indent-guides)
(require 'magit)

;; ── Apps ──────────────────────────────────────────────────────────────────────
(require 'dired-config)
(require 'helpful-config)
(require 'eat)

;; ── Org ───────────────────────────────────────────────────────────────────────
;; (require 'org-config)
;; (require 'org-modern-config)
;; (require 'org-babel)

;; ── Keybindings (always last) ─────────────────────────────────────────────────
(require 'keybindings-config)

(server-start)

;;; init.el ends here
