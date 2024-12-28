(provide 'org-babel)
;(require 'ess-site)

;; Do not ask for confirmation
(setq org-confirm-babel-evaluate nil)

;; Syntax latex
(require 'engrave-faces)
(setq org-latex-src-block-backend 'engraved)
(setq org-latex-engraved-theme t)  

(setq org-babel-python-command "python3")

(org-babel-do-load-languages
 'org-babel-load-languages
 '((R . t)
   ;; other languages you want to enable, e.g.,
   (python . t)
   ))
