(provide 'popper-config)
(require 'popper)
(require 'popper-echo)

(setq popper-reference-buffers
      '(
        ;; Emacs internals
        "\\*Messages\\*"
        "\\*scratch\\*"
        "\\*Backtrace\\*"
        "\\*Help\\*"
        "\\*Apropos\\*"
        "\\*info\\*"
        "Output\\*$"
        
        ;; Compilation/build/debug buffers
        compilation-mode
        "\\*Warnings\\*"
        "\\*Compile-Log\\*"
        "\\*debug\\*"
        "\\*GUD\\*"
        
        ;; Process/io buffers
        "\\*Async Shell Command\\*"
        "\\*Shell Command Output\\*"
        
        ;; Eshell and terminal
	"^\\*eat.*\\*$" eat-mode ;eat as a popup
	"^\\*eshell.*\\*$" eshell-mode ;eshell as a popup
        "^\\*shell.*\\*$"  shell-mode  ;shell as a popup
        "^\\*term.*\\*$"   term-mode   ;term as a popup
        "^\\*vterm.*\\*$"  vterm-mode  ;vterm as a popup
        
        ;; Programming/REPLs
        ;;"^\\*Python.*\\*$" python-mode ; Python REPL
      ))
(setq popper-echo-dispatch-keys '(?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9))
(setq popper-display-control t)
(setq popper-window-height 0.4)
(popper-mode +1)
(popper-echo-mode +1)
; Display control
;; (setq popper-display-control nil)


;; (setq display-buffer-alist
;;       '(("\\*Messages\\*\\|\\*scratch\\*\\|\\*Backtrace\\*\\|\\*Help\\*\\|\\*Apropos\\*\\|\\*info\\*\\|Output\\*$"
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3))

;;         ("\\*Warnings\\*\\|\\*Compile-Log\\*\\|\\*debug\\*\\|\\*GUD\\*"
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3))

;;         (compilation-mode
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3))

;;         ("\\*Async Shell Command\\*\\|\\*Shell Command Output\\*"
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3))

;;         ("^\\*eat.*\\*$"
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3)
;;          (mode . eat-mode))

;;         ("^\\*eshell.*\\*$"
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3)
;;          (mode . eshell-mode))

;;         ("^\\*shell.*\\*$"
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3)
;;          (mode . shell-mode))

;;         ("^\\*term.*\\*$"
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3)
;;          (mode . term-mode))

;;         ("^\\*vterm.*\\*$"
;;          (display-buffer-at-bottom)
;;          (window-height . 0.3)
;;          (mode . vterm-mode))))
