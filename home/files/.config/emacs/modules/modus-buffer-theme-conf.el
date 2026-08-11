;;; modus-buffer-theme-conf.el --- Buffer-local Modus theme policy -*- lexical-binding: t -*-
;;; Code:

(require 'modus-buffer-theme)

;; Prose uses a light reading surface while interactive terminals keep a dark
;; substrate.  The header line follows the buffer theme because
;; modeline-conf styles it to blend with the buffer background.
(setq modus-buffer-theme-rules
      '(((org-mode markdown-mode gfm-mode) . modus-operandi)
        ((term-mode eat-mode vterm-mode eshell-mode) . modus-vivendi))
      modus-buffer-theme-use-overrides nil
      modus-buffer-theme-adapt-cursor-color t
      modus-buffer-theme-include-header-line t
      modus-buffer-theme-window-accent t)

(modus-buffer-theme-global-mode 1)

(provide 'modus-buffer-theme-conf)
;;; modus-buffer-theme-conf.el ends here
