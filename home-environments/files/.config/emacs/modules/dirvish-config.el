(provide 'dirvish-config)
(dirvish-override-dired-mode)
(customize-set-variable 'dirvish-quick-access-entries
   '(("h" "~/"                          "Home")
     ("d" "~/Downloads/"                "Downloads")
     ("t" "~/.local/share/Trash/files/" "TrashCan")))

(dirvish-peek-mode) ; Preview files in minibuffer

(setq dirvish-mode-line-format
      '(:left (sort symlink) :right (omit yank index)))
(setq dirvish-attributes
      '(all-the-icons file-time file-size collapse subtree-state vc-state git-msg))

(setq delete-by-moving-to-trash t)
(setq dired-listing-switches
      "-l --almost-all --human-readable --group-directories-first --no-group")


(define-key dirvish-mode-map (kbd "C-c f") 'dirvish-fd)
(define-key dirvish-mode-map (kbd "a") 'dirvish-quick-access)
(define-key dirvish-mode-map (kbd "f") 'dirvish-file-info-menu)
(define-key dirvish-mode-map (kbd "y") 'dirvish-yank-menu)
(define-key dirvish-mode-map (kbd "N") 'dirvish-narrow)
(define-key dirvish-mode-map (kbd "^") 'dirvish-history-last)
(define-key dirvish-mode-map (kbd "s") 'dirvish-quicksort)    ; remapped `dired-sort-toggle-or-edit'
(define-key dirvish-mode-map (kbd "v") 'dirvish-vc-menu)      ; remapped `dired-view-file'
(define-key dirvish-mode-map (kbd "TAB") 'dirvish-subtree-toggle)
(define-key dirvish-mode-map (kbd "M-f") 'dirvish-history-go-forward)
(define-key dirvish-mode-map (kbd "M-b") 'dirvish-history-go-backward)
(define-key dirvish-mode-map (kbd "M-l") 'dirvish-ls-switches-menu)
(define-key dirvish-mode-map (kbd "M-m") 'dirvish-mark-menu)
(define-key dirvish-mode-map (kbd "M-t") 'dirvish-layout-toggle)
(define-key dirvish-mode-map (kbd "M-s") 'dirvish-setup-menu)
(define-key dirvish-mode-map (kbd "M-e") 'dirvish-emerge-menu)
(define-key dirvish-mode-map (kbd "M-j") 'dirvish-fd-jump)

