;;; config-tests.el --- Configuration regressions -*- lexical-binding: t -*-
;; Run: emacs --batch -l home/files/.config/emacs/tests/config-tests.el
(require 'ert)
(require 'cl-lib)
(require 'flymake)
(require 'project)

(setq user-emacs-directory (make-temp-file "sls-config-tests-" t)
      user-init-file (expand-file-name "../init.el" (file-name-directory load-file-name))
      meow-use-cursor-position-hack nil)
(load user-init-file nil t)

(defmacro sls-test-python-file (text &rest body)
  "Run BODY in a temporary file buffer containing TEXT, without starting LSP."
  (declare (indent 1))
  `(let ((directory (make-temp-file "sls-python-test-" t))
         (vc-handled-backends nil))
     (unwind-protect
         (with-temp-buffer
           (setq default-directory (file-name-as-directory directory)
                 buffer-file-name (expand-file-name "sample.py" directory))
           (setq-local before-save-hook nil
                       after-save-hook nil
                       make-backup-files nil
                       eglot--managed-mode nil)
           (insert ,text)
           (sls-python--enable-format-on-save)
           ,@body)
       (delete-directory directory t))))

(defun sls-test-file-text (file)
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(ert-deftest sls-python-save-writes-formatted-text ()
  (skip-unless (executable-find "ruff"))
  (sls-test-python-file "value=1\n"
    (save-buffer)
    (should (equal (buffer-string) "value = 1\n"))
    (should (equal (sls-test-file-text buffer-file-name) (buffer-string)))
    (should-not (buffer-modified-p))
    ;; A save must not leave a formatter waiting to replace subsequent edits.
    (goto-char (point-max))
    (insert "# newer edit\n")
    (accept-process-output nil 0.1)
    (should (equal (buffer-string) "value = 1\n# newer edit\n"))))

(ert-deftest sls-python-format-preserves-narrowing-and-markers ()
  (skip-unless (executable-find "ruff"))
  (sls-test-python-file "before=0\nvalue=1\nafter=2\n"
    (goto-char (point-min))
    (forward-line 1)
    (let ((marker (copy-marker (point))))
      (narrow-to-region (point) (line-beginning-position 2))
      (sls-python--ruff-format)
      (should (buffer-narrowed-p))
      (should (equal (buffer-string) "value = 1\n"))
      (should (= (point) (marker-position marker)))
      (save-restriction
        (widen)
        (should (equal (buffer-string) "before = 0\nvalue = 1\nafter = 2\n")))
      (set-marker marker nil))))

(ert-deftest sls-python-format-failure-keeps-original-text ()
  (skip-unless (executable-find "ruff"))
  (sls-test-python-file "def broken(\n"
    (let (warnings)
      (cl-letf (((symbol-function 'display-warning)
                 (lambda (&rest args) (push args warnings))))
        (save-buffer))
      (should warnings)
      (should (equal (buffer-string) "def broken(\n"))
      (should (equal (sls-test-file-text buffer-file-name) (buffer-string)))
      (should-not (buffer-modified-p)))))

(ert-deftest sls-python-format-does-not-insert-stderr ()
  (sls-test-python-file "value=1\n"
    (cl-letf (((symbol-function 'executable-find) (lambda (&rest _) "/fake/ruff"))
              ((symbol-function 'call-process-region)
               (lambda (_start _end _program _delete destination &rest _args)
                 (with-current-buffer (car destination) (insert "value = 1\n"))
                 (with-temp-file (cadr destination) (insert "A harmless warning\n"))
                 0)))
      (save-buffer))
    (should (equal (sls-test-file-text buffer-file-name) "value = 1\n"))))

(ert-deftest sls-python-save-without-ruff-still-works ()
  (sls-test-python-file "value=1\n"
    (cl-letf (((symbol-function 'executable-find) (lambda (&rest _) nil)))
      (save-buffer))
    (should (equal (sls-test-file-text buffer-file-name) "value=1\n"))
    (should-not (buffer-modified-p))))

(ert-deftest sls-python-save-uses-ruff-when-eglot-managed ()
  (skip-unless (executable-find "ruff"))
  (sls-test-python-file "value=1\n"
    (setq-local eglot--managed-mode t)
    (cl-letf (((symbol-function 'eglot-format-buffer)
               (lambda () (ert-fail "pylsp need not provide formatting"))))
      (save-buffer))
    (should (equal (sls-test-file-text buffer-file-name) "value = 1\n"))))

(ert-deftest sls-ruff-diagnostics-point-at-the-symbol ()
  (skip-unless (executable-find "ruff"))
  (let ((process-environment (append '("COLORTERM=truecolor" "FORCE_COLOR=1")
                                     process-environment)))
    (sls-test-python-file "print(missing)\nother\n"
      (let (done diagnostics)
        (sls-ruff-flymake
         (lambda (reported &rest _)
           (setq done t diagnostics reported)))
        (let ((deadline (+ (float-time) 5)))
          (while (and (not done) (< (float-time) deadline))
            (accept-process-output nil 0.05)))
        (should done)
        (should (= (length diagnostics) 2))
        (dolist (entry '(("missing" . 7) ("other" . 16)))
          (let ((diag (cl-find-if
                       (lambda (d) (string-match-p (car entry) (flymake-diagnostic-text d)))
                       diagnostics)))
            (should diag)
            (should (= (flymake-diagnostic-beg diag) (cdr entry)))
            (should (equal (buffer-substring (flymake-diagnostic-beg diag)
                                             (flymake-diagnostic-end diag))
                           (car entry)))))))))

(ert-deftest sls-python-keybindings-live-in-mode-maps ()
  (require 'python)
  (dolist (map (list python-mode-map
                     (and (boundp 'python-ts-mode-map) python-ts-mode-map)))
    (when (keymapp map)
      (should (eq (lookup-key map (kbd "C-c C-p")) #'sls-python-repl))
      (should (eq (lookup-key map (kbd "C-c t t")) #'sls-pytest-project))
      (should (eq (lookup-key map (kbd "C-c t f")) #'sls-pytest-file))
      (should (eq (lookup-key map (kbd "C-c t l")) #'sls-pytest-last-failed)))))

(ert-deftest sls-pytest-commands-use-project-root ()
  (skip-unless (executable-find "git"))
  (let ((root (make-temp-file "sls-pytest-project-" t)))
    (unwind-protect
        (progn
          (should (zerop (call-process "git" nil nil nil "-C" root "init" "--quiet")))
          (make-directory (expand-file-name "src/nested" root) t)
          (with-temp-buffer
            (setq default-directory (file-name-as-directory (expand-file-name "src/nested" root))
                  buffer-file-name (expand-file-name "tests/test with spaces.py" root))
            (let (calls)
              (cl-letf (((symbol-function 'compile)
                         (lambda (command &optional comint)
                           (push (list default-directory command comint) calls))))
                (sls-pytest-project)
                (sls-pytest-file)
                (sls-pytest-last-failed))
              (setq calls (nreverse calls))
              (should (= (length calls) 3))
              (dolist (call calls)
                (should (file-equal-p (car call) root))
                (should (nth 2 call)))
              (should (equal (cadar calls) "python3 -m pytest -v"))
              (should (equal (cadr (nth 1 calls))
                             (concat "python3 -m pytest -v "
                                     (shell-quote-argument buffer-file-name))))
              (should (equal (cadr (nth 2 calls)) "python3 -m pytest -v --lf")))))
      (delete-directory root t))))

(ert-deftest sls-pytest-outside-project-uses-current-directory ()
  (let ((directory (make-temp-file "sls-pytest-no-project-" t)))
    (unwind-protect
        (let ((default-directory (file-name-as-directory directory))
              ;; The runner's /tmp may itself be inside a Git worktree.
              (project-find-functions nil)
              seen)
          (cl-letf (((symbol-function 'compile)
                     (lambda (&rest _) (setq seen default-directory))))
            (sls-pytest-project))
          (should (file-equal-p seen directory)))
      (delete-directory directory t))))

(ert-deftest sls-pytest-file-requires-a-file ()
  (with-temp-buffer
    (should-error (sls-pytest-file) :type 'user-error)))

(ert-deftest sls-reload-reapplies-modules-without-duplicating-hooks ()
  (let ((hook-count (length python-mode-hook)))
    (dotimes (_ 2)
      (setq python-indent-offset 123)
      (sls-reload-init-file)
      (should (= python-indent-offset 4))
      (should (= (length python-mode-hook) hook-count))
      (should global-corfu-mode)
      (should marginalia-mode)
      (should global-display-line-numbers-mode)
      (should meow-global-mode))))

(ert-deftest sls-reload-rejects-a-missing-init-file ()
  (let ((user-init-file nil))
    (should-error (sls-reload-init-file) :type 'user-error)))

(ert-deftest sls-python-ruff-survives-real-eglot-connection ()
  (skip-unless (and (executable-find "ruff") (executable-find "pylsp")))
  (require 'python)
  (require 'eglot)
  (sls-test-python-file "value=1\nprint(missing)\n"
    (let ((python-mode-hook (remove #'eglot-ensure python-mode-hook))
          (eglot-sync-connect t)
          (eglot-connect-timeout 15)
          server)
      (unwind-protect
          (progn
            (python-mode)
            (setq server (eglot '(python-mode) (cons 'transient default-directory)
                                'eglot-lsp-server (list (executable-find "pylsp"))
                                '("python")))
            (should (eglot-managed-p))
            (should (memq #'sls-ruff-flymake flymake-diagnostic-functions))
            (should (memq #'eglot-flymake-backend flymake-diagnostic-functions))
            (save-buffer)
            (should (equal (sls-test-file-text buffer-file-name)
                           "value = 1\nprint(missing)\n"))
            (flymake-start nil t)
            (let ((deadline (+ (float-time) 8)))
              (while (and (< (float-time) deadline)
                          (not (cl-some
                                (lambda (diag)
                                  (string-match-p "F821" (flymake-diagnostic-text diag)))
                                (flymake-diagnostics))))
                (accept-process-output nil 0.05)))
            (should (cl-some
                     (lambda (diag) (string-match-p "F821" (flymake-diagnostic-text diag)))
                     (flymake-diagnostics)))
            (eglot-shutdown server)
            (setq server nil)
            (should-not (eglot-managed-p))
            (should (memq #'sls-ruff-flymake flymake-diagnostic-functions))
            (should-not (memq #'eglot-flymake-backend flymake-diagnostic-functions)))
        (when server (ignore-errors (eglot-shutdown server)))))))

(ert-deftest sls-cape-completions-stay-buffer-local ()
  (let ((defaults (copy-tree (default-value 'completion-at-point-functions))))
    (with-temp-buffer
      (text-mode)
      (should (local-variable-p 'completion-at-point-functions))
      (should (memq #'cape-tex completion-at-point-functions))
      (should-not (memq #'cape-elisp-symbol completion-at-point-functions)))
    (with-temp-buffer
      (emacs-lisp-mode)
      (should (memq #'cape-elisp-symbol completion-at-point-functions))
      (should-not (memq #'cape-tex completion-at-point-functions)))
    (should (equal defaults (default-value 'completion-at-point-functions)))
    (with-temp-buffer
      (fundamental-mode)
      (should (equal completion-at-point-functions defaults)))))

(ert-deftest sls-emoji-font-is-configured-for-new-graphical-frames ()
  (let (configured)
    (cl-letf (((symbol-function 'display-graphic-p) (lambda (frame) (eq frame 'gui)))
              ((symbol-function 'font-family-list) (lambda (&rest _) '("Noto Color Emoji")))
              ((symbol-function 'set-fontset-font)
               (lambda (&rest args) (push args configured))))
      (sls-emoji-font-setup 'terminal)
      (should-not configured)
      (should (memq #'sls-emoji-font-setup after-make-frame-functions))
      (sls-emoji-font-setup 'gui)
      (should (member '(t emoji "Noto Color Emoji" gui prepend) configured)))))

(ert-deftest sls-notmuch-fcc-files-sent-mail-without-draft-flag ()
  (skip-unless (executable-find "notmuch"))
  (require 'notmuch)
  (require 'notmuch-maildir-fcc)
  (let* ((directory (make-temp-file "sls-fcc-test-" t))
         (config (expand-file-name "notmuch-config" directory))
         (process-environment (copy-sequence process-environment)))
    (unwind-protect
        (progn
          (setenv "NOTMUCH_CONFIG" config)
          (setenv "XDG_CONFIG_HOME" directory)
          (with-temp-file config
            (insert (format "[database]\npath=%s\nhook_dir=%s\n[user]\nname=Test\nprimary_email=test@example.invalid\n[new]\ntags=new;\n[maildir]\nsynchronize_flags=true\n"
                            (expand-file-name "mail" directory)
                            (expand-file-name "hooks" directory))))
          (make-directory (expand-file-name "mail" directory))
          (make-directory (expand-file-name "hooks" directory))
          (should (zerop (call-process "notmuch" nil nil nil "new" "--no-hooks")))
          (with-temp-buffer
            (insert "From: test@example.invalid\nTo: recipient@example.invalid\nMessage-ID: <fcc-test@example.invalid>\nSubject: Synthetic Fcc test\n\nbody\n")
            (notmuch-maildir-notmuch-insert-current-buffer "Drafts" t '("+draft"))
            ;; notmuch-draft-resume removes the draft's Message-ID; sending
            ;; generates a new one. Insert never retags duplicate IDs.
            (goto-char (point-min))
            (search-forward "<fcc-test@example.invalid>")
            (replace-match "<sent-fcc-test@example.invalid>" t t)
            (notmuch-maildir-fcc-with-notmuch-insert notmuch-fcc-dirs t))
          (let ((sent (directory-files (expand-file-name "mail/Sent Items/cur" directory)
                                       nil ":2,")))
            (should (= (length sent) 1))
            (should (string-match-p ":2,S$" (car sent))))
          (with-temp-buffer
            (should (zerop (call-process "notmuch" nil t nil "count"
                                         "id:sent-fcc-test@example.invalid and tag:sent and tag:new and not tag:draft and not tag:unread and not tag:inbox")))
            (should (equal (buffer-string) "1\n"))))
      (delete-directory directory t))))

(ert-run-tests-batch-and-exit)
