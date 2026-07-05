;;; gptel-conf.el --- AI assistant via gptel -*- lexical-binding: t -*-
;;; Code:

(require 'gptel)

;; ── Backends ──────────────────────────────────────────────────────────────────

;; Claude (Anthropic) — primary backend, key read from environment
(defvar sls-gptel-claude-backend
  (gptel-make-anthropic "Claude"
    :stream t
    :key (lambda () (or (getenv "ANTHROPIC_API_KEY")
                        (auth-source-pick-first-password :host "api.anthropic.com")))))

;; Ollama — local fallback (no key needed)
(gptel-make-ollama "Ollama"
  :host "localhost:11434"
  :stream t
  :models '(llama3.2:latest deepseek-r1:latest))

;; Default: Claude Sonnet
(setq gptel-model   'claude-sonnet-4-5
      gptel-backend sls-gptel-claude-backend)

;; ── Behaviour ─────────────────────────────────────────────────────────────────

(setq gptel-default-mode        'org-mode
      gptel-expert-commands      t
      gptel-log-level            nil)

;; ── Agentic Tools ─────────────────────────────────────────────────────────────
;; Only register tools when the API is available (gptel ≥ 0.9)

(with-eval-after-load 'gptel-transient
  (when (fboundp 'gptel-make-tool)

    ;; Shell execution tool
    (gptel-make-tool
     :function (lambda (command)
                 (with-temp-buffer
                   (let ((exit (call-process-shell-command command nil t)))
                     (format "Exit %d:\n%s" exit (buffer-string)))))
     :name        "shell_run"
     :description "Run a shell command and return its output and exit code."
     :args        '((:name "command" :type string
                     :description "Shell command to execute"))
     :confirm     t
     :category    "system")

    ;; Read file tool
    (gptel-make-tool
     :function (lambda (path)
                 (condition-case err
                     (with-temp-buffer
                       (insert-file-contents (expand-file-name path))
                       (buffer-string))
                   (error (format "Error reading %s: %s" path (error-message-string err)))))
     :name        "read_file"
     :description "Read the contents of a file."
     :args        '((:name "path" :type string
                     :description "Absolute or home-relative file path"))
     :category    "filesystem")

    ;; Write file tool — lets gptel apply edits, not just read.
    ;; You stay in control: gptel confirms tool calls before running them.
    (gptel-make-tool
     :function (lambda (path content)
                 (condition-case err
                     (let ((file (expand-file-name path)))
                       (with-temp-buffer
                         (insert content)
                         (write-region (point-min) (point-max) file))
                       (format "Wrote %d bytes to %s" (length content) file))
                   (error (format "Error writing %s: %s" path (error-message-string err)))))
     :name        "write_file"
     :description "Write (create or overwrite) a file with the given content."
     :args        '((:name "path" :type string
                     :description "Absolute or home-relative file path")
                    (:name "content" :type string
                     :description "Full file content to write"))
     :confirm     t
     :category    "filesystem")

    ;; List directory tool
    (gptel-make-tool
     :function (lambda (path)
                 (let ((dir (expand-file-name path)))
                   (if (file-directory-p dir)
                       (mapconcat #'identity (directory-files dir) "\n")
                     (format "Not a directory: %s" dir))))
     :name        "list_dir"
     :description "List files in a directory."
     :args        '((:name "path" :type string
                     :description "Directory path to list"))
     :category    "filesystem")))

;; ── UI / Keybindings ──────────────────────────────────────────────────────────

;; Open / send are bound globally; menu gives access to backends and directives
(global-set-key (kbd "C-c a")   #'gptel)
(global-set-key (kbd "C-c A")   #'gptel-menu)
(global-set-key (kbd "C-c RET") #'gptel-send)
(global-set-key (kbd "C-c C-a") #'gptel-add)

;; Rewrite / refactor: mark region, then C-c r
(global-set-key (kbd "C-c C-r") #'gptel-rewrite)

(provide 'gptel-conf)
;;; gptel-conf.el ends here
