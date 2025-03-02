(require 'dap-mode)
;; Enabling only some features
(setq dap-auto-configure-features '(sessions locals controls tooltip))
(require 'dap-python)
;; if you installed debugpy, you need to set this
;; https://github.com/emacs-lsp/dap-mode/issues/306
(setq dap-python-debugger 'debugpy)
(provide 'dap-config)
