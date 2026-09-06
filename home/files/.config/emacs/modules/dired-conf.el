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
  (diredfl-global-mode 1))

(provide 'dired-conf)
;;; dired-conf.el ends here
