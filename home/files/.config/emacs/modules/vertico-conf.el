;;; vertico-conf.el --- Vertico completion UI -*- lexical-binding: t -*-
;;; Code:

(use-package vertico
  :init
  (vertico-mode 1)
  :custom
  (vertico-resize nil)
  (vertico-cycle t))

(provide 'vertico-conf)
;;; vertico-conf.el ends here
