;;; eglot-conf.el --- LSP via built-in eglot -*- lexical-binding: t -*-
;;; Code:

(require 'eglot)

;; ── Performance ───────────────────────────────────────────────────────────────

(setq eglot-autoshutdown t          ; shut down server when last buffer closes
      eglot-confirm-server-edits nil ; apply workspace edits without asking
      eglot-report-progress nil      ; keep minibuffer clean
      eglot-events-buffer-size 0)   ; disable event logging (saves memory)

;; Boost completion responsiveness (eglot uses Jsonrpc under the hood)
(setq jsonrpc-default-request-timeout 10)

;; ── Server programs ───────────────────────────────────────────────────────────

;; Python: pylsp (python-lsp-server)
(add-to-list 'eglot-server-programs
             '((python-mode python-ts-mode) . ("pylsp")))

;; Scheme/Guile: already installed as guile-lsp-server
(add-to-list 'eglot-server-programs
             '(scheme-mode . ("guile-lsp-server")))

;; ── Mode hooks ────────────────────────────────────────────────────────────────

(add-hook 'python-mode-hook    #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)
(add-hook 'scheme-mode-hook    #'eglot-ensure)

;; ── UI integration ────────────────────────────────────────────────────────────

;; Show LSP docs in eldoc (already the default, but be explicit)
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (setq-local eldoc-documentation-strategy
                        #'eldoc-documentation-compose-eagerly)))

;; Symbol-under-point highlighting is provided automatically by
;; `eglot-managed-mode` when the server reports textDocument/documentHighlight,
;; so no extra hook is needed.

(provide 'eglot-conf)
;;; eglot-conf.el ends here
