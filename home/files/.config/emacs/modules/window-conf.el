;;; window-conf.el --- Window management configuration for Emacs
;;; Commentary:
;; This module configures display-buffer behavior for side windows,
;; specifically for Ibuffer and the Bookmark List, and customizes
;; ibuffer display formats.
;;; Code:

;; Make ibuffer use display-buffer instead of switch-to-buffer
(setq ibuffer-use-other-window t)

;; Display Ibuffer in a right side window
(add-to-list 'display-buffer-alist
             '("^\*Ibuffer\*$"
               (display-buffer-in-side-window)
               (side . right)
               (slot . 0)
               (window-width . 0.33)
               (preserve-selected-window . nil)
               (window-parameters . ((no-delete-other-windows . t)))))

;; Display Bookmark List in a right side window
(add-to-list 'display-buffer-alist
             '("^\*Bookmark List\*$"
               (display-buffer-in-side-window)
               (side . right)
               (slot . 0)
               (window-width . 0.33)
               (preserve-selected-window . nil)
               (window-parameters . ((no-delete-other-windows . t)))))

;; Hook to force use of display-buffer for Bookmark List
(defun my/bookmark-list-display-hook ()
  "When *Bookmark List* opens, redisplay it via `display-buffer` so rules apply."  
  (when (string= (buffer-name) "*Bookmark List*")
    (let ((buf (current-buffer)))
      (quit-window)
      (display-buffer buf))))

(add-hook 'bookmark-bmenu-mode-hook #'my/bookmark-list-display-hook)

;; Customize ibuffer to show only the name column
(setq ibuffer-formats
      '((mark " " (name 30 30 :left :elide))))

(provide 'window-conf)
;;; window-conf.el ends here
