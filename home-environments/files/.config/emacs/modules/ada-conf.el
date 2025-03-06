(when (and (fboundp 'treesit-available-p)
           (treesit-available-p))
  (use-package ada-ts-mode
    :ensure t
    :defer t ; autoload updates `auto-mode-alist'
    :custom (ada-ts-mode-indent-backend 'lsp) ; Use Ada LS indentation
    :bind (:map ada-ts-mode-map
                (("C-c C-b" . ada-ts-mode-defun-comment-box)
                 ("C-c C-o" . ada-ts-mode-find-other-file)
                 ("C-c C-p" . ada-ts-mode-find-project-file)))
    :init
    ;; Configure source blocks for Org Mode.
    (with-eval-after-load 'org-src
      (add-to-list 'org-src-lang-modes '("ada" . ada-ts)))))

;; Configure Electric Pair

(use-package elec-pair
  :ensure nil ; built-in
  :hook (ada-ts-mode . electric-pair-local-mode))



(provide 'ada-conf)
