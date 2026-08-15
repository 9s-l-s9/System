(define-module (services agent-launchers)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (agent-launcher-services))

;; Install the agent launcher scripts as real executables in ~/.local/bin so
;; they work anywhere a program is spawned directly (Emacs/VALSI, dmenu,
;; compile commands), not only in interactive shells where aliases expand.
;; Publish both the public CLI names expected by integrations and the explicit
;; *-guix names used when a caller wants to select these wrappers deliberately.
;; Like agent-skills, the links point at the live repo checkout, so editing a
;; script takes effect without reconfiguring.

(define launchers
  '(("pi" . "pi-guix.scm")
    ("pi-guix" . "pi-guix.scm")
    ("claude" . "claude-guix.scm")
    ("claude-guix" . "claude-guix.scm")
    ("codex" . "codex-guix.scm")
    ("codex-guix" . "codex-guix.scm")
    ("opencode" . "open-code-guix.scm")
    ("opencode-guix" . "open-code-guix.scm")))

(define agent-launchers-activation
  #~(begin
      (use-modules ((guix build utils)
                    #:select (mkdir-p))
                   (ice-9 format))

      (let* ((home (getenv "HOME"))
             (scripts (string-append home "/Projects/System/scripts")))
        (define (ensure-launcher-link name script)
          (let ((link (string-append home "/.local/bin/" name))
                (target (string-append scripts "/" script)))
            (unless (file-exists? target)
              (format (current-error-port)
                      "agent-launchers: script does not exist: ~a~%" target)
              (exit 1))
            (mkdir-p (dirname link))
            (cond
             ((equal? (false-if-exception (readlink link)) target)
              #t)
             ((false-if-exception (readlink link))
              (delete-file link)
              (symlink target link))
             ((file-exists? link)
              (format (current-error-port)
                      "agent-launchers: refusing to replace non-symlink path: ~a~%"
                      link)
              (format (current-error-port)
                      "agent-launchers: move it aside and re-run guix home reconfigure.~%")
              (exit 1))
             (else
              (symlink target link)))))

        (for-each (lambda (entry)
                    (ensure-launcher-link (car entry) (cdr entry)))
                  '#$launchers))))

(define (agent-launcher-services)
  (list
   (simple-service 'agent-launchers
                   home-activation-service-type
                   agent-launchers-activation)
   ;; Session-wide, so shepherd children (the Emacs daemon) inherit it at
   ;; login, unlike shell aliases. Append it so packages installed in Guix
   ;; profiles win when both provide a command (notably VALSI's pinned Pi).
   (simple-service 'agent-launchers-path
                   home-environment-variables-service-type
                   '(("PATH" . "$PATH:$HOME/.local/bin")))))
