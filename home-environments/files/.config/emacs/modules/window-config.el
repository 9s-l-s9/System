;; Make ibuffer use display-buffer instead of switch-to-buffer
(setq ibuffer-use-other-window t)

(add-to-list 'display-buffer-alist
             '("^\\*Ibuffer\\*$"
               (display-buffer-in-side-window)
               (side . right)
               (slot . 0)
               (window-width . 0.33)
               (preserve-selected-window . nil)
               (window-parameters . ((no-delete-other-windows . t)))))

;; Customize ibuffer to show only the name column
(setq ibuffer-formats
      '((mark " " (name 30 30 :left :elide))))


(provide 'window-conf)
