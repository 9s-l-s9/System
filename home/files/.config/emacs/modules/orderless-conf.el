(require 'orderless) 
(use-package orderless
  :custom
  (orderless-matching-styles '(orderless-initialism orderless-flex))
  (completion-styles '(orderless basic))
  :config
  (defun orderless-fast-dispatch (word index total)
    (and (= index 0) (= total 1) (length< word 4)
         (cons 'orderless-literal-prefix word)))

  (orderless-define-completion-style orderless-fast
    (orderless-style-dispatchers '())
    (orderless-matching-styles '(orderless-flex orderless-regexp))))

(provide 'orderless-conf)
