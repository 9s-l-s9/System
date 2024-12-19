(provide 'dashboard-config)
(require 'dashboard)
 (dashboard-setup-startup-hook)
 (setq dashboard-projects-backend 'project-el)
 (setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
;; (setq dashboard-startup-banner "~/Images/01-Wallpaper/guts.jpg")

 (setq dashboard-items '((recents  . 3)
;; ;;                         ;(bookmarks . 5)
;; ;;                         (projects . 3)
;; ;;                         ;(agenda . 5)
;; ;;                         (registers . 3))
))

;; 					;(setq dashboard-icon-type 'all-the-icons) ;; use `all-the-icons' package
;(setq dashboard-icon-type 'nerd-icons) ;; use `nerd-icons' package
;; ;(setq dashboard-display-icons-p t) ;; display icons on both GUI and terminal
;; ;(setq dashboard-set-heading-icons t)
;; 					;(setq dashboard-set-file-icons t)
;; (dashboard-insert-shortcut 'Projects "c" "Current projects:")
 (setq dashboard-set-navigator t)
 (setq dashboard-set-init-info t)
