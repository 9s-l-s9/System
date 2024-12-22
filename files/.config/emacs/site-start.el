(when (require 'guix-emacs nil t)
  (guix-emacs-autoload-packages)
  (advice-add 'package-load-all-descriptors :after #'guix-emacs-load-package-descriptors))
