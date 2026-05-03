(add-to-list 'load-path "~/.config/emacs/modules/")
(require 'use-package)
(require 'sls-functions)
(require 'general-settings)
					; -- UI -- ;
(require 'general-ui-config)
					; -- General Navigation & Editing --
(require 'rg)
(rg-enable-default-bindings)
(require 'undo-tree)
(global-undo-tree-mode)
(setq undo-tree-history-directory-alist '(("." . "~/.cache/emacs")))
(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

(require 'focus-conf)
(require 'imenu-list-conf)
(require 'window-conf)


					; -- Completion & Snippets --
(require 'corfu-conf)
(require 'cape-conf)
(require 'consult)
(require 'orderless-conf)
(require 'vertico)
  (setq vertico-resize nil)
  (vertico-mode 1)
(require 'marginalia-conf) 
(all-the-icons-completion-mode)
(add-hook 'marginalia-mode-hook #'all-the-icons-completion-marginalia-setup)

					; -- Programming --
(require 'eglot-conf)
(require 'python-conf)
(require 'dap-config)
;(require 'flycheck-config)
(require 'highlight-indent-guides)
(require 'magit)
					; -- Languages / Modes --
;;(require 'markdown-preview-mode)
;; (require 'lean4-conf)
;; (require 'ada-conf)

					; -- Apps --

;;(require 'dashboard-config)
(require 'dired-config)
;(require 'eshell-config)
;;(require 'ebib-config)
;(require 'pdf-tools-config)
(require 'helpful-config)
(require 'eat)

					; -- Org Configurations --
;; (require 'org-config)
;; (require 'org-noter-config)
;; (require 'org-modern-config)
;; (require 'org-babel)
;; (require 'org-transclusion)

;; (require 'gptel-config)
;; (require 'citar-conf)

;; Load at the end
(require 'keybindings-config)
(server-start)

;;; init.el ends here
