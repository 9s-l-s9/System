(provide 'eshell-config)

(require 'eshell-prompt-extras)

;; Change the Eshell prompt function to use eshell-prompt-extras
(setq eshell-highlight-prompt nil
      eshell-prompt-function 'epe-theme-multiline-with-status)
