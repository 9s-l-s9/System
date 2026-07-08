;;; general-settings.el --- Core Emacs settings -*- lexical-binding: t -*-
;;; Code:

(setq user-full-name "Samuel Levi Schmidt"
      user-email-address (concat "schmidt.l.samuel" "@" "gmail.com")
      copyright-names-regexp (format "%s <%s>"
                                     user-full-name
                                     user-mail-address))

(setq package-selected-packages nil)
;; Suppress only native-comp chatter; keep treesit warnings visible so we
;; notice when grammar loading actually breaks.
(setq warning-suppress-log-types '((comp)))

;; Trash instead of delete
(setq delete-by-moving-to-trash t)

;; Watch webp and similar images via external converter
(setq image-use-external-converter t)

;; Reload files changed on disk automatically
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

;; `user-emacs-directory' is set in early-init.el so recentf/savehist/url
;; capture the relocated value at load time.

;; Backup and auto-save into cache
(let ((backup-dir (expand-file-name "backups" user-emacs-directory)))
  (make-directory backup-dir t)
  (setq backup-directory-alist         `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,backup-dir t))))

(setq create-lockfiles nil
      backup-by-copying   t
      version-control     t
      delete-old-versions t
      vc-make-backup-files t
      kept-old-versions   5
      kept-new-versions   10)

;; Preserve clipboard content before a kill overwrites it
(setq save-interprogram-paste-before-kill t)

;; Scrolling
(setq-default scroll-preserve-screen-position t
              scroll-conservatively 1
              scroll-margin 0
              next-screen-context-lines 0)

;; Better defaults from well-known configs
;; Performance: disable bidi for left-to-right text
(setq-default bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; Don't fontify during a keystroke burst; catch up when input pauses.
(setq redisplay-skip-fontification-on-input t)

;; Icon fonts (all-the-icons) trigger font-cache compaction while
;; scrolling, causing stutter; keep the caches instead.
(setq inhibit-compacting-font-caches t)

;; Handle very long lines gracefully
(global-so-long-mode 1)

;; Larger process read buffer (benefits LSP and subprocesses)
(setq read-process-output-max (* 1024 1024))

;; Persist minibuffer history across sessions
(savehist-mode 1)
(setq savehist-additional-variables '(search-ring regexp-search-ring))

;; Remember cursor position in visited files
(save-place-mode 1)

;; Recent files
(recentf-mode 1)
(setq recentf-max-menu-items 50
      recentf-max-saved-items 100)

;; Undo window layout changes with C-c left/right
(winner-mode 1)

;; Pair brackets/parens automatically
(electric-pair-mode 1)

;; Single space after sentence end
(setq sentence-end-double-space nil)

(provide 'general-settings)
;;; general-settings.el ends here
