(add-to-list 'load-path "~/.config/emacs/modules/")


;; (setq debug-on-error t)

(require 'use-package)
(require 'own-functions)
					; -- UI -- ;
(require 'general-ui-config)
;; (require 'telephone-mod)
;; (require 'min-modeline)

					; -- General Navigation & Editing --

(setq-default scroll-preserve-screen-position t
                scroll-conservatively 1 ; affects `scroll-step'
                scroll-margin 0
                next-screen-context-lines 0)


(require 'consult-config)

(require 'rg)
(rg-enable-default-bindings)

(require 'undo-tree)
(global-undo-tree-mode)

(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

(require 'sudo-edit)
(require 'imenu-list-config)

					; -- Completion & Snippets --
(require 'corfu-conf)

(require 'cape-conf)
(require 'orderless-conf)
(require 'vertico)
(setq vertico-resize nil)
(vertico-mode 1)
(require 'marginalia-conf) 
; (all-the-icons-completion-mode)
; (add-hook 'marginalia-mode-hook #'all-the-icons-completion-marginalia-setup)


					; -- Programming --

;;(require 'eglot-conf)
;;(require 'treesitter-conf)
(require 'flycheck-config)
(require 'highlight-indent-guides)
(require 'magit)
;; (require 'dap-config)
(require 'markdown-preview-mode)
;; (require 'lean4-conf)
;; (require 'ada-conf)

					; -- Apps --

(require 'dashboard-config)
(require 'dired-config)
;(require 'eshell-config)
(require 'ebib-config)
;(require 'pdf-tools-config)
(require 'popper-config)
(require 'helpful-config)
(require 'eat)

;; (require 'gptel-config)
;; (require 'citar-conf)

;; Load at the end
(require 'keybindings-config)
(server-start)

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil)
 '(warning-suppress-log-types '((treesit) (comp)))
 '(warning-suppress-types '((treesit))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
