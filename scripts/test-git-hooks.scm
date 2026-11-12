#!/usr/bin/env -S guix repl -q --
!#
(add-to-load-path (string-append (dirname (current-filename)) "/../home"))
(use-modules (services git)
             (lib git-hooks)
             (guix gexp)
             (guix store)
             (guix derivations)
             (guix monads)
             (guix build utils)
             ((guix build syscalls) #:select (mkdtemp!))
             (ice-9 popen)
             (ice-9 textual-ports)
             (srfi srfi-64))

;; Test the installed programs, not an approximation of their generated code.
(define hooks
  (with-store store
    (let ((drv (run-with-store store
                 (lower-object
                  (file-union
                   "test-git-hooks"
                   (map (lambda (name)
                          (list name ((@@ (services git) git-hook) name)))
                        git-hook-names))))))
      (build-derivations store (list drv))
      (derivation->output-path drv))))
(define directory (mkdtemp! "/tmp/test-git-hooks.XXXXXX"))
(define repository (string-append directory "/repo with spaces"))
(define worktree (string-append directory "/linked tree"))
(define receiver (string-append directory "/receiver"))
(define result (string-append directory "/result"))
(define message (string-append directory "/message"))
(define original-directory (getcwd))

(define (write-text path text)
  (call-with-output-file path (lambda (port) (display text port))))
(define (read-text path)
  (call-with-input-file path get-string-all))
(define (git-status . args)
  (status:exit-val (apply system* "git" args)))
(define (run-hook name . args)
  (apply git-status "hook" "run" name "--" args))
(define (fixture name code stdin?)
  (let ((path (string-append repository "/.git/hooks/" name)))
    (call-with-output-file path
      (lambda (port)
        (format port "#!~a -s\n!#\n" (which "guile"))
        (write '(use-modules (ice-9 textual-ports)) port)
        (write `(call-with-output-file ,result
                  (lambda (port)
                    (write (list (cdr (command-line))
                                 ,(if stdin? '(get-string-all (current-input-port)) ""))
                           port))) port)
        (write `(exit ,code) port)))
    (chmod path #o700)
    path))

;; Isolate all Git configuration; never change the user's home or repositories.
(setenv "GIT_CONFIG_NOSYSTEM" "1")
(setenv "GIT_CONFIG_GLOBAL" (string-append directory "/gitconfig"))
(write-text (getenv "GIT_CONFIG_GLOBAL")
            (format #f "[core]\n hooksPath = ~a\n[user]\n name = Test\n email = test@example.invalid\n[commit]\n gpgSign = false\n" hooks))
(setenv "GIT_TERMINAL_PROMPT" "0")
(test-begin "git-hooks")
(dynamic-wind
  (lambda () #t)
  (lambda ()
    (invoke "git" "init" "-q" "-b" "main" repository)
    (chdir repository)
    (write-text message "A normal commit\n")
    (for-each
     (lambda (name)
       (unless (member name '("push-to-checkout" "fsmonitor-watchman" "proc-receive"))
         (test-equal (string-append "absent hook: " name) 0
                     (run-hook name message)))
       (let ((path (fixture name 13 #f)))
         (test-equal (string-append "repository status: " name) 13
                     (run-hook name message "argument with spaces"))
         (test-equal (string-append "repository arguments: " name)
                     (list (list message "argument with spaces") "")
                     (call-with-input-file result read))
         (delete-file path)))
     git-hook-names)
    (let* ((path (fixture "pre-push" 0 #t))
           ;; `git hook run' disconnects stdin unless --to-stdin is supplied.
           ;; Invoke the installed entry point just as Git/LFS does on push.
           (port (open-pipe* OPEN_WRITE (string-append hooks "/pre-push")
                            "origin" "remote with spaces"))
           (input "refs/heads/main aaa refs/heads/main bbb\n"))
      (display input port)
      (test-equal "pre-push accepts stdin" 0 (status:exit-val (close-pipe port)))
      (test-equal "LFS-style pre-push gets untouched stdin and arguments"
                  (list '("origin" "remote with spaces") input)
                  (call-with-input-file result read))
      (delete-file path))
    (for-each
     (lambda (trailer)
       (write-text message (string-append "Message\n\n" trailer "\n"))
       (test-equal "Claude attribution rejected" 1 (run-hook "commit-msg" message)))
     '("Co-Authored-By: Claude <noreply@anthropic.com>"
       "co-authored-by: assistant <bot@anthropic.com>"
       "Claude-Session: abc" "Generated with [Claude Code]"))
    (write-text message "Message\n\nCo-Authored-By: Human <human@example.invalid>\n")
    (test-equal "human attribution accepted" 0 (run-hook "commit-msg" message))
    (test-equal "missing fsmonitor requests a full scan" 1
                (run-hook "fsmonitor-watchman" "2" "token"))
    (invoke "git" "commit" "-q" "--allow-empty" "-m" "Initial")
    (invoke "git" "worktree" "add" "-q" "--detach" worktree)
    (let ((path (fixture "pre-commit" 17 #f)))
      (chdir worktree)
      (test-equal "linked worktree finds shared hooks" 17 (run-hook "pre-commit"))
      (chdir repository)
      (delete-file path))
    (let ((path (string-append repository "/.git/hooks/pre-commit")))
      (symlink (string-append hooks "/pre-commit") path)
      (test-equal "self-link fails instead of recursing" 1 (run-hook "pre-commit"))
      (delete-file path))
    ;; Installing push-to-checkout must preserve updateInstead's default:
    ;; update a clean checkout, but reject staged AND unstaged changes.
    (write-text "tracked" "initial\n")
    (invoke "git" "add" "tracked")
    (invoke "git" "commit" "-q" "-m" "Track file")
    (invoke "git" "clone" "-q" repository receiver)
    (invoke "git" "-C" receiver "config" "receive.denyCurrentBranch" "updateInstead")
    (write-text "tracked" "updated\n")
    (invoke "git" "commit" "-q" "-am" "Update file")
    (test-equal "push updates clean checked-out tree" 0
                (git-status "push" "-q" receiver "main"))
    (test-equal "receiver file updated" "updated\n"
                (read-text (string-append receiver "/tracked")))
    (write-text "tracked" "third\n")
    (invoke "git" "commit" "-q" "-am" "Third version")
    (write-text (string-append receiver "/tracked") "local edits\n")
    (test-assert "push refuses unstaged receiver changes"
      (not (zero? (git-status "push" "-q" receiver "main"))))
    (invoke "git" "-C" receiver "add" "tracked")
    (test-assert "push refuses staged receiver changes"
      (not (zero? (git-status "push" "-q" receiver "main"))))
    (test-equal "receiver edits preserved" "local edits\n"
                (read-text (string-append receiver "/tracked"))))
  (lambda ()
    (chdir original-directory)
    (delete-file-recursively directory)))
(define failures (test-runner-fail-count (test-runner-current)))
(test-end "git-hooks")
(exit (if (zero? failures) 0 1))
