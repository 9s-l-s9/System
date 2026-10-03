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
;; When eglot is managing the buffer, defer to `eglot-format-buffer' so the LSP
;; sees the edits and stays in sync. Otherwise, finish `ruff format' before
;; writing the file: a background result could overwrite edits made after save.

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
  "Pick the right formatter for the current buffer."
  (if (bound-and-true-p eglot--managed-mode)
      (ignore-errors (eglot-format-buffer))
    (sls-python--ruff-format)))

(defun sls-python--enable-format-on-save ()
  "Install the buffer-local format-on-save hook."
  (add-hook 'before-save-hook #'sls-python--format-on-save nil t))

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
                             ;; Ruff and `flymake-diag-region' use one-based columns.
                             (col  (string-to-number (match-string 2)))
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

(defun sls-python--bind-test-keys ()
  "Buffer-local test keybindings for Python."
  (local-set-key (kbd "C-c C-p") #'sls-python-repl)
  (local-set-key (kbd "C-c t t") #'sls-pytest-project)
  (local-set-key (kbd "C-c t f") #'sls-pytest-file)
  (local-set-key (kbd "C-c t l") #'sls-pytest-last-failed))

(dolist (hook '(python-mode-hook python-ts-mode-hook))
  (add-hook hook #'sls-python--indent-setup)
  (add-hook hook #'sls-python--enable-format-on-save)
  (add-hook hook #'sls-maybe-enable-ruff-flymake)
  (add-hook hook #'sls-python--bind-test-keys))

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
