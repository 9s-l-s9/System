;;; naur-conf.el --- NAUR artifact application -*- lexical-binding: t -*-
;;; Code:

(require 'naur)
(require 'naur-meow)

(when (fboundp 'valsi-global-mode)
  (valsi-global-mode -1))

(naur-global-mode 1)
(naur-meow-setup)

(provide 'naur-conf)
;;; naur-conf.el ends here
