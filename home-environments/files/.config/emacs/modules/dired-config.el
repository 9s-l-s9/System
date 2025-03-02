(provide 'dired-config)
(require 'all-the-icons-dired)
(add-hook 'dired-mode-hook 'all-the-icons-dired-mode)
(setq all-the-icons-dired-monochrome nil)

(require 'diredfl)
(diredfl-global-mode 1)

;; Open some files in other programs
(setq dired-guess-shell-alist-user
      '(
        ("\\.\\(mp[34]\\|m4a\\|ogg\\|flac\\|webm\\|mkv\\)" "mpv" "xdg-open")
	))



;; (require 'dired-preview)

;; Default values for demo purposes
;; (setq dired-preview-delay 0.1)
;; (defun my-dired-previexw-to-the-right ()
;;   "My preferred `diredx-preview-display-action-alist-function'."
;;   '((display-buffer-inx-side-window)
;;     ;; (side . right)
;;     (width . 0.6)))

;; (setq dired-preview-display-action-alist-function #'my-dired-preview-to-the-right)

;; (setq dired-preview-max-size (expt 2 20))
					;
;; (setq dired-preview-ignored-extensions-regexp
;;     (concat "\\."
;;              "\\(mkv\\|webm\\|mp4\\|mp3\\|ogg\\|m4a"
;;              "\\|gz\\|zst\\|tar\\|xz\\|rar\\|zip"
;;              "\\|iso\\|epub\\)"))

;;(setq dired-guess-shell-alist-user
;;      '(("\\.\\(png\\|jpe?g\\|tiff\\)" "feh" "xdg-open")
;;        ("\\.\\(mp[34]\\|m4a\\|ogg\\|flac\\|webm\\|mkv\\)" "mpv" "xdg-open")
;;		(".*" "xdg-open")))

;; Enable `dired-preview-mode' in a given Dired buffer or do it
;; globally:
;; (dired-preview-global-mode 1)

(setq dired-listing-switches "-alhU")
