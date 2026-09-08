;;; eglot-conf.el --- LSP via built-in eglot -*- lexical-binding: t -*-
;;; Code:

;; eglot is loaded lazily (autoloaded, or via `eglot-ensure' below); we
;; avoid `(require 'eglot)' here so the daemon doesn't pay eglot's
;; load cost at startup.

;; ── Performance ───────────────────────────────────────────────────────────────

(setq eglot-autoshutdown t          ; shut down server when last buffer closes
      eglot-confirm-server-edits nil ; apply workspace edits without asking
      eglot-report-progress nil      ; keep minibuffer clean
      eglot-events-buffer-size 0)   ; disable event logging (saves memory)

;; Boost completion responsiveness (eglot uses Jsonrpc under the hood)
(setq jsonrpc-default-request-timeout 10)

;; Batch didChange notifications instead of sending one per keystroke.
(setq eglot-send-changes-idle-time 0.5)
;; Don't let the server touch the buffer while typing.
(setq eglot-ignored-server-capabilities
      '(:inlayHintProvider :documentOnTypeFormattingProvider))
;; Eldoc: fewer echo-area redraws while typing.
(setq eldoc-idle-delay 0.8
      eldoc-echo-area-use-multiline-p nil)

;; ── Server programs ───────────────────────────────────────────────────────────

;; Python: eglot already ships a default entry for pylsp; no override needed.

;; Scheme/Guile: not in eglot's defaults
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(scheme-mode . ("guile-lsp-server"))))

;; ── Mode hooks ────────────────────────────────────────────────────────────────

(add-hook 'python-mode-hook    #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)
(add-hook 'scheme-mode-hook    #'eglot-ensure)

;; ── UI integration ────────────────────────────────────────────────────────────

;; Eldoc keeps the default strategy: `compose-eagerly' asks the server for
;; hover + signature on every idle pause and redraws the echo area each time.

;; Symbol-under-point highlighting is provided automatically by
;; `eglot-managed-mode` when the server reports textDocument/documentHighlight,
;; so no extra hook is needed.

(provide 'eglot-conf)
;;; eglot-conf.el ends here
