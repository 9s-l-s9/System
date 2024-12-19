(require 'ivy)
;(require 'ivy-posframe)

;; Enable Ivy for completion.
(ivy-mode 1)

;; Configure Ivy's appearance and behavior.
(setq ivy-use-virtual-buffers t
      ivy-count-format "(%d/%d) "
      ivy-wrap t)

;;; ; Enable Ivy Posframe.
;; (ivy-posframe-mode 1)

;; ;; Configure Ivy Posframe's appearance.
;; (setq ivy-posframe-parameters
;;       '((left-fringe . 8)
;;         (right-fringe . 8)))

;; ;; Specify which commands should use Ivy Posframe.
;; ;; If you want all commands to use Ivy Posframe, use `t'.
;; (setq ivy-posframe-display-functions-alist '((t . ivy-posframe-display-at-frame-center)))

;; ;; Set the height of the posframe
;; (setq ivy-posframe-height-alist
;;       '((swiper . 20)
;;         (t . 10)))

(provide 'ivy-config)
