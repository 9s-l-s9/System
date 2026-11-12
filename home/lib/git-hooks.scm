(define-module (lib git-hooks)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 textual-ports)
  #:export (git-hook-names dispatch-git-hook))

;; Keep in sync with https://git-scm.com/docs/githooks.
(define git-hook-names
  '("applypatch-msg" "pre-applypatch" "post-applypatch" "pre-commit"
    "pre-merge-commit" "prepare-commit-msg" "commit-msg" "post-commit"
    "pre-rebase" "post-checkout" "post-merge" "pre-push" "pre-receive"
    "update" "proc-receive" "post-receive" "post-update"
    "reference-transaction" "push-to-checkout" "pre-auto-gc" "post-rewrite"
    "sendemail-validate" "fsmonitor-watchman" "p4-changelist"
    "p4-prepare-changelist" "p4-post-changelist" "p4-pre-submit"
    "post-index-change"))

(define (claude-attribution? file)
  (let ((pattern (make-regexp
                  (string-append "^Co-Authored-By:.*(claude|anthropic)"
                                 "|^Claude-Session:|Generated with \\[?Claude")
                  regexp/icase regexp/newline)))
    (call-with-input-file file
      (lambda (port) (regexp-exec pattern (get-string-all port))))))

(define (common-directory git)
  ;; reference-transaction also runs during `git init', before HEAD exists
  ;; and rev-parse recognizes the repository. Git supplies GIT_DIR then.
  (cond
   ((getenv "GIT_COMMON_DIR") => canonicalize-path)
   ((getenv "GIT_DIR")
    => (lambda (directory)
         (let ((file (string-append directory "/commondir")))
           (canonicalize-path
            (if (file-exists? file)
                (let ((common (string-trim-right
                               (call-with-input-file file get-string-all)
                               #\newline)))
                  (if (string-prefix? "/" common) common
                      (string-append directory "/" common)))
                directory)))))
   (else
    (let* ((port (open-pipe* OPEN_READ git "rev-parse"
                            "--path-format=absolute" "--git-common-dir"))
           (output (get-string-all port))
           (status (close-pipe port)))
      (unless (zero? status) (error "cannot locate repository hooks"))
      (string-trim-right output #\newline)))))

(define (dispatch-git-hook name git shell push-to-checkout-sample)
  (let* ((args (cdr (command-line)))
         (hook (string-append (common-directory git) "/hooks/" name)))
    ;; Claude Code attribution is disabled in services/claude.scm too.
    ;; This check deliberately covers the same Claude/Anthropic trailers.
    (when (and (string=? name "commit-msg")
               (claude-attribution? (car args)))
      (display "commit-msg: Claude attribution is not allowed in commit messages\n"
               (current-error-port))
      (exit 1))
    (cond
     ((and (file-exists? hook) (access? hook X_OK))
      ;; An accidental link back to the installed dispatcher must not loop.
      (when (equal? (canonicalize-path hook)
                    (canonicalize-path (car (command-line))))
        (error "repository hook links back to the global dispatcher" hook))
      ;; Exec preserves arguments, stdin (notably LFS pre-push), and status.
      (apply execl hook hook args))
     ((string=? name "push-to-checkout")
      ;; Merely installing this hook overrides Git's updateInstead default.
      ;; Git ships an implementation of that default; use it when the repo
      ;; has no override, including its checks for staged/unstaged changes.
      (setenv "PATH" (string-append (dirname git) ":" (or (getenv "PATH") "")))
      (apply execl shell shell push-to-checkout-sample args))
     ((member name '("fsmonitor-watchman" "proc-receive"))
      ;; These hooks implement protocols: empty success is not a valid reply.
      ;; A failed fsmonitor request makes Git scan every file normally.
      (exit 1))
     (else (exit 0)))))
