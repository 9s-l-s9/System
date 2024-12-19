(provide 'eglot-config)
(require 'eglot)

(add-to-list 'eglot-server-programs '((c++-mode c-mode) "ccls"))
