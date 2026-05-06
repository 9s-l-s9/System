;;; general-ui-conf.el --- General UI improvements -*- lexical-binding: t -*-
;; Author: Samuel Schmidt <samuel@schmidt-contact.com>
;;; Code:

;; No fringe but nice glyphs for truncated and wrapped lines
(fringe-mode '(0 . 0))
;; Note: global-visual-line-mode omitted — conflicts with header-line redisplay

;; General
(setq widget-image-enable nil)

;; Indentation lines
(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)
(setq highlight-indent-guides-method 'character)
(setq highlight-indent-guides-auto-character-face-perc '70)

(global-hl-line-mode +1)

;; Theme
(load-theme 'modus-operandi t)
(setq custom-safe-themes t)

;; Emoji: prefer a real color emoji font when present; fall back silently.
(when (member "Noto Color Emoji" (font-family-list))
  (set-fontset-font t 'emoji "Noto Color Emoji" nil 'prepend))

;; Visual pulse on focus change (built-in beacon alternative)
;; https://karthinks.com/software/batteries-included-with-emacs/
(defun pulse-line (&rest _)
  "Pulse the current line."
  (pulse-momentary-highlight-one-line (point)))

(dolist (command '(scroll-up-command scroll-down-command
                                     recenter-top-bottom other-window))
  (advice-add command :after #'pulse-line))

;; Line spacing
(setq-default line-spacing 2)
;; Underline at descent position, not baseline
(setq x-underline-at-descent-line t)

;; Cursor shape is owned by Meow (per modal state); we only disable blink.
(blink-cursor-mode 0)

(show-paren-mode t)

;; Relative line numbers
(setq display-line-numbers-current-absolute t
      display-line-numbers-grow-only        t
      display-line-numbers-type             'relative
      display-line-numbers-width            4
      display-line-numbers-width-start      t)
(global-display-line-numbers-mode)

(provide 'general-ui-conf)
;;; general-ui-conf.el ends here
