;; (setq comp-deferred-compilation t)
(setq delete-by-moving-to-trash t)

(setq backup-directory-alist `(("." . "~/.config/emacs/backups")))
(setq auto-save-file-name-transforms `((".*" "~/.config/emacs/backups" t)))
(setq undo-tree-history-directory-alist '(("." . "~/.config/emacs/backups")))

; Watch webp and similar images
(setq image-use-external-converter t)


; Reload if changed on disk
(global-auto-revert-mode 1)
(provide 'general-setting)
