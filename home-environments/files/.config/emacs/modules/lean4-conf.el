;; You need to modify the following line
(setq load-path (cons "~/Projects/lean4-mode" load-path))
(setq lean4-rootdir "~/.elan/")
;; (setq lean4-mode-required-packages '(dash f flycheck magit-section s))

;; (require 'package)
;; (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
;; (package-initialize)
;; (let ((need-to-refresh t))
;;   (dolist (p lean4-mode-required-packages)
;;     (when (not (package-installed-p p))
;;       (when need-to-refresh
;;         (package-refresh-contents)
;;         (setq need-to-refresh nil))
;;       (package-install p))))

(require 'lean4-mode)

(provide 'lean4-conf)
