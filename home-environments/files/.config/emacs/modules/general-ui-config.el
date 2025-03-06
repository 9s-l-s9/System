;;; general-ui-config.el --- Contains just some general UI improvements of emacs.
;;; Commentary:
;; Author: Samuel Schmidt <samuel@schmidt-contact.com>
;;;; Code:

(provide 'general-ui-config)


;; No fringe but nice glyphs for truncated and wrapped lines
(fringe-mode '(0 . 0))
(global-visual-line-mode)


;; General
(setq widget-image-enable nil)

;; Indentation lines
(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)
(setq highlight-indent-guides-method 'character)
(setq highlight-indent-guides-auto-character-face-perc '70)


(global-hl-line-mode +1)

;; Theme 
(setq custom-safe-themes t)
;; (require 'doom-themes)
;; (require 'nano-theme)
;;(load-theme 'nano-light)
;; (load-theme 'nano-light)
(load-theme 'modus-operandi t)
(setq custom-safe-themes t)


;; Emoji font
(set-fontset-font t 'symbol "all-the-icons" nil 'prepend)

;; add visual pulse when changing focus, like beacon but built-in
;; from from https://karthinks.com/software/batteries-included-with-emacs/
(defun pulse-line (&rest _)
  "Pulse the current line."
  (pulse-momentary-highlight-one-line (point)))

(dolist (command '(scroll-up-command scroll-down-command
                                     recenter-top-bottom other-window))
  (advice-add command :after #'pulse-line))

;; Disable some UI elements
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;; Font and frame size
;; (set-face-font 'default "Courier Prime 16")

;; Line spacing, can be 0 for code and 1 or 2 for text
(setq-default line-spacing 2)
;; Underline line at descent position, not baseline position
(setq x-underline-at-descent-line t)

;; No ugly button for checkboxes
(setq widget-image-enable nil)

;; Line cursor and no blink
(set-default 'cursor-type  '(bar . 1))
(blink-cursor-mode 0)

;; No sound
(setq visible-bell t)
(setq ring-bell-function 'ignore)

;; Paren mode is part of the theme
(show-paren-mode t)

;; Line Numbers
;; display-line-numbers variables
  (setq display-line-numbers-current-absolute t
        display-line-numbers-grow-only        t
        display-line-numbers-type             'relative
        display-line-numbers-width            4
        display-line-numbers-width-start      t)

