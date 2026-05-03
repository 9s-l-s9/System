;;; pdf-tools-conf.el --- -*- lexical-binding: t -*-
(require 'pdf-tools)

(add-hook 'doc-view-mode-hook (lambda () (require 'pdf-tools)))
(add-hook 'pdf-view-mode-hook (lambda ()
                                (pdf-view-midnight-minor-mode 1)))

(with-eval-after-load 'pdf-tools
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-width))

(setq pdf-view-use-scaling t)
(pdf-tools-install)



(provide 'pdf-tools-conf)
