(setq user-full-name "Samuel Levi Schmidt"
      user-email-address (concat "schmidt.l.samuel" "@" "gmail.com")
      copyright-names-regexp (format "%s <%s>"
                                       user-full-name
                                       user-mail-address))


(setq package-selected-packages nil)
(setq warning-suppress-log-types '((treesit) (comp)))
(setq warning-suppress-types '((treesit)))

(setq delete-by-moving-to-trash t)
; Watch webp and similar images
(setq image-use-external-converter t)

; Reload if changed on disk
(global-auto-revert-mode 1)

;; keep ~/.config/emacs/ clean
(setq user-emacs-directory "~/.cache/emacs/")
(setq url-history-file
      (expand-file-name "url/history" user-emacs-directory))

;; Set up backup and auto-save directories
(let ((backup-dir
       (expand-file-name "backups" user-emacs-directory)))
  (setq backup-directory-alist `(("." . ,backup-dir)))
  (setq auto-save-file-name-transforms `((".*" ,backup-dir t)))
  (setq undo-tree-history-directory-alist `(("." . ,backup-dir)))
)
;; backups
(setq create-lockfiles nil
      backup-by-copying t
      version-control t
      delete-old-versions t
      vc-make-backup-files t
      kept-old-versions 10
      kept-new-versions 10)

;; Save whatever’s in the current (system) clipboard before
;; replacing it with the Emacs’ text.
(setq save-interprogram-paste-before-kill t)


;; Srcolling
(setq-default scroll-preserve-screen-position t
                scroll-conservatively 1 ; affects `scroll-step'
                scroll-margin 0
                next-screen-context-lines 0)

(provide 'general-settings)
