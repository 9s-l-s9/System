(add-to-list 'load-path "~/.config/emacs/modules/")
(require 'use-package)
(require 'sls-functions)
(require 'general-settings)
					; -- UI -- ;
(require 'general-ui-config)
					; -- General Navigation & Editing --
(require 'consult-config)
(require 'rg)
(rg-enable-default-bindings)
(require 'undo-tree)
(global-undo-tree-mode)
(setq undo-tree-history-directory-alist '(("." . "~/.cache/emacs")))
(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)


					; -- Completion & Snippets --
(require 'corfu-conf)
(require 'cape-conf)
(require 'orderless-conf)
(require 'vertico)
  (setq vertico-resize nil)
  (vertico-mode 1)
(require 'marginalia-conf) 
(all-the-icons-completion-mode)
(add-hook 'marginalia-mode-hook #'all-the-icons-completion-marginalia-setup)


					; -- Programming --

;;(require 'eglot-conf)
;;(require 'treesitter-conf)
(require 'flycheck-config)
(require 'highlight-indent-guides)
(require 'magit)

					; -- Apps --

(require 'dashboard-config)
(require 'dired-config)
(require 'ebib-config)
;(require 'pdf-tools-config)
(require 'popper-config)
(require 'helpful-config)
(require 'eat)

(require 'keybindings-config)
(server-start)
