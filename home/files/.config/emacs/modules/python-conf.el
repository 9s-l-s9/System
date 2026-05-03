;;; python-conf.el --- Python development configuration -*- lexical-binding: t -*-
;;; Code:

;; ── Tree-sitter mode ──────────────────────────────────────────────────────────

;; Redirect python-mode → python-ts-mode when tree-sitter is available.
;; python-ts-mode gives better syntax highlighting and structural navigation.
(when (treesit-available-p)
  (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))

;; ── Indentation ───────────────────────────────────────────────────────────────

(setq python-indent-offset 4)

(dolist (hook '(python-mode-hook python-ts-mode-hook))
  (add-hook hook (lambda ()
                   (setq-local tab-width        4
                               indent-tabs-mode nil))))

;; ── Ruff: format buffer in-place on save ──────────────────────────────────────

(defun sls-ruff-format-buffer ()
  "Format current Python buffer with `ruff format' via stdin/stdout."
  (when (executable-find "ruff")
    (let* ((source (buffer-substring-no-properties (point-min) (point-max)))
           (formatted
            (with-temp-buffer
              (insert source)
              (when (zerop
                     (call-process-region
                      (point-min) (point-max)
                      "ruff" t t nil
                      "format" "--quiet"
                      "--stdin-filename" (or (buffer-file-name) "buffer.py")
                      "-"))
                (buffer-string)))))
      (when (and formatted (not (string= formatted source)))
        (save-excursion
          (delete-region (point-min) (point-max))
          (insert formatted))))))

(dolist (hook '(python-mode-hook python-ts-mode-hook))
  (add-hook hook (lambda ()
                   (add-hook 'before-save-hook #'sls-ruff-format-buffer nil t))))

;; ── Ruff: lint via flymake (independent of eglot diagnostics) ────────────────

(defun sls-ruff-flymake (report-fn &rest _)
  "Flymake backend: run `ruff check' on the buffer."
  (unless (executable-find "ruff")
    (error "ruff not on PATH"))
  (let ((source (current-buffer)))
    (let ((proc
           (make-process
            :name    "ruff-flymake"
            :noquery t
            :buffer  (generate-new-buffer " *ruff*")
            :command `("ruff" "check"
                       "--output-format=concise" "--quiet"
                       "--stdin-filename"
                       ,(or (buffer-file-name) "buffer.py")
                       "-")
            :sentinel
            (lambda (proc _event)
              (when (memq (process-status proc) '(exit signal))
                (let ((diags nil))
                  (with-current-buffer (process-buffer proc)
                    (goto-char (point-min))
                    (while (re-search-forward
                            "^[^:]+:\\([0-9]+\\):\\([0-9]+\\): \\([A-Z][0-9]+\\) \\(.+\\)$"
                            nil t)
                      (let* ((line (string-to-number (match-string 1)))
                             (col  (max 0 (1- (string-to-number (match-string 2)))))
                             (code (match-string 3))
                             (msg  (match-string 4))
                             (region (flymake-diag-region source line col)))
                        (push (flymake-make-diagnostic
                               source (car region) (cdr region)
                               :warning (format "%s: %s" code msg))
                              diags))))
                  (funcall report-fn diags))
                (kill-buffer (process-buffer proc)))))))
      (process-send-region proc (point-min) (point-max))
      (process-send-eof proc))))

;; Activate ruff flymake only when NOT managed by eglot (eglot adds its own)
(defun sls-maybe-enable-ruff-flymake ()
  "Add ruff flymake backend if eglot is not active."
  (unless (bound-and-true-p eglot--managed-mode)
    (add-hook 'flymake-diagnostic-functions #'sls-ruff-flymake nil t)
    (flymake-mode 1)))

(dolist (hook '(python-mode-hook python-ts-mode-hook))
  (add-hook hook #'sls-maybe-enable-ruff-flymake))

;; ── REPL ─────────────────────────────────────────────────────────────────────

(setq python-shell-interpreter      "python3"
      python-shell-interpreter-args "-i")

(defun sls-python-repl ()
  "Open a Python REPL in eat, or fall back to inferior-python."
  (interactive)
  (if (fboundp 'eat)
      (eat "python3")
    (run-python python-shell-interpreter t t)))

;; ── Testing: pytest ───────────────────────────────────────────────────────────

(defun sls-pytest-project ()
  "Run the full pytest suite for the current project."
  (interactive)
  (compile "python3 -m pytest -v" t))

(defun sls-pytest-file ()
  "Run pytest on the current file."
  (interactive)
  (compile (format "python3 -m pytest -v %s"
                   (shell-quote-argument (buffer-file-name)))
           t))

(defun sls-pytest-last-failed ()
  "Re-run only tests that failed in the last run."
  (interactive)
  (compile "python3 -m pytest -v --lf" t))

;; ── Keybindings (buffer-local) ────────────────────────────────────────────────

(dolist (hook '(python-mode-hook python-ts-mode-hook))
  (add-hook hook
            (lambda ()
              (local-set-key (kbd "C-c C-p") #'sls-python-repl)
              (local-set-key (kbd "C-c t t") #'sls-pytest-project)
              (local-set-key (kbd "C-c t f") #'sls-pytest-file)
              (local-set-key (kbd "C-c t l") #'sls-pytest-last-failed))))

(provide 'python-conf)
;;; python-conf.el ends here
