;;; dired-conf.el --- -*- lexical-binding: t -*-
;;; Code:

;; Open some files in other programs
(setq dired-guess-shell-alist-user
      '(
        ("\\.\\(mp[34]\\|m4a\\|ogg\\|flac\\|webm\\|mkv\\)" "mpv" "xdg-open")
	))

(setq dired-listing-switches "-alhU")

;; nerd-icons-dired and diredfl are only needed inside dired buffers;
;; load them lazily instead of paying their cost at startup.
(with-eval-after-load 'dired
  (add-hook 'dired-mode-hook 'nerd-icons-dired-mode)
  ;; `define-globalized-minor-mode' makes `diredfl-mode' set this flag from
  ;; its after-hook, but the natively compiled diredfl.eln runs that hook
  ;; before the variable's defvar has been evaluated, so every dired buffer
  ;; fails with "Symbol's value as variable is void".  Predefining it is
  ;; harmless when the ordering is right and fixes it when it is not.
  (defvar diredfl-mode--set-explicitly nil)
  (diredfl-global-mode 1))

(provide 'dired-conf)
;;; dired-conf.el ends here
