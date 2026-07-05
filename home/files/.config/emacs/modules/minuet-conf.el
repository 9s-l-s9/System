;;; minuet-conf.el --- AI inline completion via Minuet -*- lexical-binding: t -*-
;;; Commentary:
;; Minuet is the inline-completion ("Copilot alternative") layer, complementary
;; to gptel (chat) and ECA (autonomous agent).  It reuses the same Claude key
;; (ANTHROPIC_API_KEY) and rides the corfu/cape stack already configured.
;;
;; Two ways to use it after adding a key in keybindings-conf.el:
;;   - On-demand popup via corfu:        minuet-show-suggestion
;;   - As-you-type ghost text:           M-x minuet-auto-suggestion-mode
;; Guarded so a missing package never breaks startup.
;;; Code:

(when (require 'minuet nil t)
  (require 'auth-source)

  ;; Provider: reuse the Claude backend / ANTHROPIC_API_KEY.
  (setq minuet-provider 'claude)
  ;; Resolve the key like gptel does: env var first, then auth-source
  ;; (~/.authinfo.gpg).  A function is required here; a bare string would be
  ;; treated as an env-var name and fail when the var isn't exported.
  (with-eval-after-load 'minuet
    (when (boundp 'minuet-claude-options)
      ;; Haiku: cheap + fast, the right tradeoff for inline completion.
      (plist-put minuet-claude-options :model "claude-haiku-4-5")
      (plist-put minuet-claude-options :api-key
                 (lambda () (or (getenv "ANTHROPIC_API_KEY")
                                (auth-source-pick-first-password
                                 :host "api.anthropic.com"))))))

  ;; Keep completions snappy: cap output + a sane timeout.
  (setq minuet-n-completions 2
        minuet-request-timeout 3)

  ;; Keybindings live in keybindings-conf.el.  These are local to Minuet's
  ;; active suggestion map, so they stay with the feature configuration.
  (with-eval-after-load 'minuet
    (when (boundp 'minuet-active-mode-map)
      (define-key minuet-active-mode-map (kbd "M-RET") #'minuet-accept-suggestion)
      (define-key minuet-active-mode-map (kbd "C-g")   #'minuet-dismiss-suggestion)
      (define-key minuet-active-mode-map (kbd "M-n")   #'minuet-next-suggestion)
      (define-key minuet-active-mode-map (kbd "M-p")   #'minuet-previous-suggestion)))

  ;; Opt in to as-you-type ghost text only in code buffers (comment out if you
  ;; prefer purely on-demand completion).
  (add-hook 'prog-mode-hook #'minuet-auto-suggestion-mode))

(provide 'minuet-conf)
;;; minuet-conf.el ends here
