(require 'cape)

;; Enable Corfu completion UI
;; See the Corfu README for more configuration tips.

(use-package cape
  :init
  (dolist (mode '(text-mode-hook prog-mode-hook conf-mode-hook))
          (add-hook mode
                    (lambda ()
                      (add-to-list 'completion-at-point-functions #'cape-file)
                      (add-to-list 'completion-at-point-functions #'cape-tex)
                      (add-to-list 'completion-at-point-functions #'cape-dabbrev)
                      (add-to-list 'completion-at-point-functions #'cape-keyword)
                      (add-to-list 'completion-at-point-functions #'cape-elisp-block)
                      (add-to-list 'completion-at-point-functions #'cape-elisp-symbol)))))

(provide 'cape-conf)
