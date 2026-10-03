;;; marginalia-conf.el --- -*- lexical-binding: t -*-
(use-package marginalia
  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode 1))

(provide 'marginalia-conf)
