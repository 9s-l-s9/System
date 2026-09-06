;;; helpful-conf.el --- -*- lexical-binding: t -*-
(with-eval-after-load 'helpful
  (define-key helpful-mode-map [remap revert-buffer] #'helpful-update))
(provide 'helpful-conf)
