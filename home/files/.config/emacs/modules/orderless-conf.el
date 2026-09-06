;;; orderless-conf.el --- -*- lexical-binding: t -*-
(require 'orderless)
(use-package orderless
  :custom
  (orderless-matching-styles '(orderless-initialism orderless-flex))
  (completion-styles '(orderless basic)))

(provide 'orderless-conf)
