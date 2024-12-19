(require 'company)
(add-to-list 'company-backends 'company-files)
(add-hook 'after-init-hook 'global-company-mode)
(provide 'company-conf)

