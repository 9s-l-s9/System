;;; window-conf.el --- Unified side-panel navigation -*- lexical-binding: t -*-
;;; Commentary:
;; All navigation panels (ibuffer, bookmarks, imenu, dired sidebar, recent
;; files) are placed in the same right-side slot so they replace each other —
;; one panel visible at a time, all navigated with j/k (meow normal) or n/p
;; (meow motion).
;;; Code:

;; ── Side-panel slot ───────────────────────────────────────────────────────────
;;
;; slot 0, right side, 28 % width.  All navigation buffers share this slot so
;; opening one automatically hides the previous one.

(defconst sls-side-panel-alist
  '((display-buffer-in-side-window)
    (side . right)
    (slot . 0)
    (window-width . 0.28)
    (preserve-selected-window . t)
    (window-parameters . ((no-delete-other-windows . t)))))

(dolist (pattern '("^\\*Ibuffer\\*$"
                   "^\\*Bookmark List\\*$"
                   "^\\*Ilist\\*$"           ; imenu-list
                   "^\\*Dired Sidebar\\*$"
                   "^\\*Recent Files\\*$"))
  (add-to-list 'display-buffer-alist (cons pattern sls-side-panel-alist)))

;; ── ibuffer ───────────────────────────────────────────────────────────────────

;; Show only the buffer name column (clean sidebar look)
(setq ibuffer-formats '((mark " " (name 30 30 :left :elide))))
(setq ibuffer-use-other-window t)

;; ── Bookmark list ─────────────────────────────────────────────────────────────

;; Ensure the bookmark list respects display-buffer-alist instead of
;; switching directly.
(defun sls--bookmark-list-use-display-buffer ()
  "Re-display *Bookmark List* through `display-buffer' so side-panel rules apply."
  (when (string= (buffer-name) "*Bookmark List*")
    (let ((buf (current-buffer)))
      (quit-window)
      (select-window (display-buffer buf)))))

(add-hook 'bookmark-bmenu-mode-hook #'sls--bookmark-list-use-display-buffer)

;; ── imenu-list ────────────────────────────────────────────────────────────────

(setq imenu-list-focus-after-activation t
      imenu-list-auto-resize            nil)

;; ── winner-mode (undo/redo window layouts) ────────────────────────────────────

;; winner-mode is enabled in general-settings.el; bind its commands here.
(global-set-key (kbd "C-c <left>")  #'winner-undo)
(global-set-key (kbd "C-c <right>") #'winner-redo)

(provide 'window-conf)
;;; window-conf.el ends here
