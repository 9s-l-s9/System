;;; init.el --- Samuel's Emacs configuration -*- lexical-binding: t -*-
;;; Code:

(defconst sls-config-directory
  (file-name-directory (or load-file-name user-init-file))
  "Directory containing the configuration currently being loaded.")

(add-to-list 'load-path (expand-file-name "modules/" sls-config-directory))

(defun sls-load-module (module)
  "Read configuration MODULE from source, including when reloading init.el.
Package dependencies still use `require'; only our settings are re-evaluated."
  (load (expand-file-name (format "modules/%s.el" module) sls-config-directory)
        nil t))

(require 'use-package)
(setq use-package-always-defer t
      use-package-expand-minimally t)

;; ── Core settings ─────────────────────────────────────────────────────────────
(sls-load-module 'sls-functions)
(sls-load-module 'general-settings)

;; ── UI ────────────────────────────────────────────────────────────────────────
(sls-load-module 'general-ui-conf)
(sls-load-module 'modus-buffer-theme-conf)
(sls-load-module 'modeline-conf)

(use-package highlight-indent-guides
  :hook (prog-mode . highlight-indent-guides-mode))

;; ── Navigation & editing ──────────────────────────────────────────────────────
(use-package rg
  :commands (rg rg-menu rg-project rg-dwim))

;; Built-in undo does the work (meow-undo drives it); vundo visualizes the
;; tree on demand. Replaced undo-tree, whose per-edit tree bookkeeping and
;; history serialization were pure runtime cost.
(use-package vundo
  :commands (vundo))

(with-eval-after-load 'ediff
  (setq ediff-split-window-function 'split-window-horizontally
        ediff-window-setup-function 'ediff-setup-windows-plain))

(sls-load-module 'focus-conf)
(sls-load-module 'app-ui-conf)
(sls-load-module 'window-conf)
(sls-load-module 'recentf-conf)
(sls-load-module 'imenu-conf)

;; ── Completion ────────────────────────────────────────────────────────────────
(sls-load-module 'corfu-conf)
(sls-load-module 'cape-conf)
(use-package consult
  :commands (consult-buffer consult-line consult-ripgrep consult-find consult-imenu))
(sls-load-module 'orderless-conf)
(sls-load-module 'vertico-conf)
(sls-load-module 'marginalia-conf)

;; marginalia-mode is already on (marginalia-conf), so a marginalia-mode-hook
;; would never fire; run the setup directly once the mode is enabled.
(use-package nerd-icons-completion
  :hook (after-init . nerd-icons-completion-mode)
  :config (nerd-icons-completion-marginalia-setup))

;; ── Programming ───────────────────────────────────────────────────────────────
(sls-load-module 'eglot-conf)
(sls-load-module 'python-conf)
(sls-load-module 'dap-conf)
(sls-load-module 'gptel-conf)   ; chat / rewrite, user-in-the-loop
(sls-load-module 'eca-conf)     ; autonomous agent (emacs-eca)
;; (sls-load-module 'minuet-conf)  ; AI inline completion; disabled (needs API key)
(sls-load-module 'whisper-conf)  ; local speech-to-text (no-op until emacs-whisper installed)

(sls-load-module 'magit-conf)

;; ── AI/ML ─────────────────────────────────────────────────────────────────────

(sls-load-module 'valsi-conf)

;; ── Apps ──────────────────────────────────────────────────────────────────────
(sls-load-module 'dired-conf)

(sls-load-module 'pdf-conf)
(sls-load-module 'helpful-conf)
(sls-load-module 'eat-conf)
(sls-load-module 'notmuch-conf)

;; ── Org ───────────────────────────────────────────────────────────────────────
;; (sls-load-module 'org-conf)
;; (sls-load-module 'org-modern-conf)
;; (require 'org-babel)
;; (sls-load-module 'citar-conf)

;; Load at the end
(sls-load-module 'keybindings-conf)

;;; init.el ends here
