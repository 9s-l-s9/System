;;; python-conf.el --- Python development configuration -*- lexical-binding: t -*-
;;; Code:

;; ── Tree-sitter mode ──────────────────────────────────────────────────────────

;; Tell Emacs where Guix installs grammar shared libraries so it can find
;; tree-sitter-python (and friends) without prompting to download them.
(with-eval-after-load 'treesit
  (dolist (dir '("~/.guix-home/profile/lib/tree-sitter"
                 "/run/current-system/profile/lib/tree-sitter"))
    (add-to-list 'treesit-extra-load-path (expand-file-name dir))))

;; Redirect python-mode → python-ts-mode when tree-sitter is available.
;; python-ts-mode gives better syntax highlighting and structural navigation.
(when (and (treesit-available-p)
           (treesit-language-available-p 'python))
  (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))

;; ── Indentation ───────────────────────────────────────────────────────────────

(setq python-indent-offset 4)

(defun sls-python--indent-setup ()
  "Buffer-local indentation defaults for Python."
  (setq-local tab-width        4
              indent-tabs-mode nil))

;; ── Format on save ────────────────────────────────────────────────────────────
;;
;; Ruff owns formatting, including buffers managed by Eglot (pylsp need not
;; provide a formatter). Ordinary buffer edits notify Eglot of the changes.
;; Finish before writing: a background result could overwrite later edits.

(defun sls-python--ruff-format ()
  "Format the whole buffer before saving, preserving point and markers.
On failure, leave the text intact and report Ruff's error.  Keep stderr
separate from formatted source, including when Ruff exits successfully."
  (when-let* ((ruff (executable-find "ruff")))
    (let ((output (generate-new-buffer " *ruff-format*"))
          (errors (make-temp-file "sls-ruff-format-"))
          (coding-system-for-read 'utf-8-unix)
          (coding-system-for-write 'utf-8-unix))
      (unwind-protect
          (save-restriction
            (widen)
            (let ((status (call-process-region
                           (point-min) (point-max) ruff nil (list output errors) nil
                           "format" "--quiet" "--stdin-filename"
                           (or buffer-file-name "buffer.py") "-")))
              (if (eq status 0)
                  (atomic-change-group
                    (replace-buffer-contents output))
                (display-warning
                 'sls-python
                 (format "Ruff formatting failed (%s); saving without formatting.\n%s"
                         status
                         (with-temp-buffer
                           (insert-file-contents errors)
                           (buffer-string)))))))
        (kill-buffer output)
        (delete-file errors)))))

(defun sls-python--format-on-save ()
  "Run Ruff before saving, whether or not Eglot manages the buffer."
  (sls-python--ruff-format))

(defun sls-python--enable-format-on-save ()
  "Install the buffer-local format-on-save hook."
  (add-hook 'before-save-hook #'sls-python--format-on-save nil t))

;; ── Ruff: lint via flymake (independent of eglot diagnostics) ────────────────

(defvar-local sls-python--ruff-proc nil
  "In-flight Ruff Flymake process for the current buffer.")

(defun sls-ruff-flymake (report-fn &rest _)
  "Flymake backend: run `ruff check' on the buffer."
  (unless (executable-find "ruff")
    (error "ruff not on PATH"))
  (when (process-live-p sls-python--ruff-proc)
    (kill-process sls-python--ruff-proc))
  (let* ((source (current-buffer))
         ;; Use pipes and disable color env vars (an entry without `=' unsets
         ;; it in `process-environment') so Ruff never emits ANSI escapes.
         (process-environment (append '("NO_COLOR=1" "FORCE_COLOR" "CLICOLOR_FORCE")
                                      process-environment))
         (proc
          (make-process
           :name            "ruff-flymake"
           :noquery         t
           :connection-type 'pipe
           :buffer          (generate-new-buffer " *ruff*")
           :command         `("ruff" "check"
                              "--output-format=concise" "--quiet"
                              "--stdin-filename"
                              ,(or (buffer-file-name) "buffer.py")
                              "-")
           :sentinel
           (lambda (proc _event)
             (when (memq (process-status proc) '(exit signal))
               (unwind-protect
                   (when (and (buffer-live-p source)
                              (eq proc (buffer-local-value 'sls-python--ruff-proc source)))
                     (let ((diags nil))
                       (with-current-buffer (process-buffer proc)
                         (goto-char (point-min))
                         (while (re-search-forward
                                 "^[^:]+:\\([0-9]+\\):\\([0-9]+\\): \\([A-Z]+[0-9]+\\) \\(.+\\)$"
                                 nil t)
                           (let* ((line (string-to-number (match-string 1)))
                                  ;; Ruff and `flymake-diag-region' use one-based columns.
                                  (col  (string-to-number (match-string 2)))
                                  (code (match-string 3))
                                  (msg  (match-string 4))
                                  (region (flymake-diag-region source line col)))
                             (push (flymake-make-diagnostic
                                    source (car region) (cdr region)
                                    :warning (format "%s: %s" code msg))
                                   diags))))
                       (funcall report-fn (nreverse diags))))
                 (when (buffer-live-p (process-buffer proc))
                   (kill-buffer (process-buffer proc)))))))))
    (setq sls-python--ruff-proc proc)
    (save-restriction
      (widen)
      (process-send-region proc (point-min) (point-max)))
    (process-send-eof proc)))

(defvar eglot-stay-out-of)

(defun sls-python--flymake-setup ()
  "Keep Ruff diagnostics when Eglot connects or disconnects."
  (when (derived-mode-p 'python-mode 'python-ts-mode)
    (require 'flymake)
    ;; Only Python opts out; Scheme and other modes keep Eglot's defaults.
    (setq-local eglot-stay-out-of
                (cons 'flymake (remove 'flymake
                                       (and (boundp 'eglot-stay-out-of)
                                            eglot-stay-out-of))))
    (add-hook 'flymake-diagnostic-functions #'sls-ruff-flymake nil t)
    (if (and (fboundp 'eglot-managed-p) (eglot-managed-p))
        (add-hook 'flymake-diagnostic-functions #'eglot-flymake-backend nil t)
      (remove-hook 'flymake-diagnostic-functions #'eglot-flymake-backend t))
    (flymake-mode 1)))

(add-hook 'eglot-managed-mode-hook #'sls-python--flymake-setup)

(dolist (hook '(python-mode-hook python-ts-mode-hook))
  (remove-hook hook #'sls-maybe-enable-ruff-flymake) ; migrate a running daemon
  (add-hook hook #'sls-python--indent-setup)
  (add-hook hook #'sls-python--enable-format-on-save)
  (add-hook hook #'sls-python--flymake-setup))

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

(defun sls-python--pytest (args)
  "Run pytest with ARGS from the project root, or the current directory."
  (require 'project)
  (let* ((project (project-current nil))
         (default-directory (if project (project-root project) default-directory)))
    (compile (mapconcat #'shell-quote-argument
                        (append '("python3" "-m" "pytest" "-v") args) " ")
             t)))

(defun sls-pytest-project ()
  "Run the full pytest suite for the current project."
  (interactive)
  (sls-python--pytest nil))

(defun sls-pytest-file ()
  "Run pytest on the current file."
  (interactive)
  (unless buffer-file-name (user-error "This buffer is not visiting a file"))
  (sls-python--pytest (list (expand-file-name buffer-file-name))))

(defun sls-pytest-last-failed ()
  "Re-run only tests that failed in the last run."
  (interactive)
  (sls-python--pytest '("--lf")))

(provide 'python-conf)
;;; python-conf.el ends here
