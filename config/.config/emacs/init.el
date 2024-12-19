;; replacing it with the Emacs’ text. (setq native-comp-speed 3) (setq fast-but-imprecise-scrolling 't) (setq jit-lock-defer-time 0) (setq gc-cons-threshold most-positive-fixnum) (setq comp-speed 2) (setq max-specpdl-size 3200) (setq max-lisp-eval-depth 3200) (require 'vertico) (setq vertico-resize nil) (vertico-mode 1)

(setq native-comp-async-report-warnings-errors nil)
(setq fast-but-imprecise-scrolling 't)
(add-to-list 'load-path "~/.config/emacs/modules/")

(setq frame-resize-pixelwise t
      frame-inhibit-implied-resize t
      frame-title-format '("%b")
      ring-bell-function 'ignore
      use-dialog-box t ; only for mouse events, which I seldom use
      use-file-dialog nil
      delete-by-moving-to-trash t
      
      use-short-answers t
      inhibit-splash-screen t
      inhibit-startup-screen t
      inhibit-x-resources t
      inhibit-startup-echo-area-message user-login-name ; read the docstring
      inhibit-startup-buffer-menu t)





(setq backup-directory-alist `(("." . "~/.config/emacs/backups")))
(setq auto-save-file-name-transforms `((".*" "~/.config/emacs/backups" t)))
(setq undo-tree-history-directory-alist '(("." . "~/.config/emacs/backups")))
(global-auto-revert-mode 1)


;; Save whatever’s in the current (system) clipboard before
;; replacing it with the Emacs’ text.
;; https://github.com/dakrone/eos/blob/master/eos.org
(setq save-interprogram-paste-before-kill t)


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
; (require 'marginalia-conf) 
; (all-the-icons-completion-mode)
; (add-hook 'marginalia-mode-hook #'all-the-icons-completion-marginalia-setup)


					; -- Programming --

(require 'eglot-conf)
;; (require 'treesitter-conf)
(require 'flycheck-config)
(require 'highlight-indent-guides)
(require 'magit)
;; (require 'dap-config)

					; -- Languages / Modes --
(require 'markdown-preview-mode)
;; (require 'lean4-conf)


					; -- Apps --

(require 'dashboard-config)
(require 'dired-config)
;(require 'eshell-config)
(require 'ebib-config)
					; (require 'pdf-tools-config)
(require 'popper-config)
(require 'helpful-config)
(require 'eat)


					; -- Org Configurations --
;; (require 'org-config)
;; (require 'org-noter-config)
(require 'org-modern-config)
(require 'org-babel)
;(require 'org-transclusion)

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
