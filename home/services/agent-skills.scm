(define-module (services agent-skills)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (agent-skills-service))

(define agent-skills-activation
  #~(begin
      (use-modules ((guix build utils)
                    #:select (mkdir-p))
                   (ice-9 format))

      (let* ((home (getenv "HOME"))
             (agents-dir (string-append home "/Projects/System/.agents"))
             (skills (string-append agents-dir "/skills"))
             (rules (string-append agents-dir "/AGENTS.md")))
        (define (ensure-live-link target link)
          (let ((parent (dirname link)))
            (mkdir-p parent)
            (cond
             ((equal? (false-if-exception (readlink link)) target)
              #t)
             ((false-if-exception (readlink link))
              (delete-file link)
              (symlink target link))
             ((file-exists? link)
              (format (current-error-port)
                      "agent-skills: refusing to replace non-symlink path: ~a~%"
                      link)
              (format (current-error-port)
                      "agent-skills: move it aside and re-run guix home reconfigure.~%")
              (exit 1))
             (else
              (symlink target link)))))

        (for-each (lambda (target)
                    (unless (file-exists? target)
                      (format (current-error-port)
                              "agent-skills: source does not exist: ~a~%"
                              target)
                      (exit 1)))
                  (list skills rules))

        ;; Codex, OpenCode, and Pi support ~/.agents/skills.  Claude Code
        ;; uses ~/.claude/skills, so link it to the same canonical tree.
        (ensure-live-link skills (string-append home "/.agents/skills"))
        (ensure-live-link skills (string-append home "/.claude/skills"))

        ;; Global instructions: one file, linked to each harness's own
        ;; global path.
        ;; Antigravity: verified with and without the link (2026-11-01).
        (for-each (lambda (link)
                    (ensure-live-link rules (string-append home link)))
                  '("/.claude/CLAUDE.md"
                    "/.codex/AGENTS.md"
                    "/.pi/agent/AGENTS.md"
                    "/.gemini/config/AGENTS.md")))))

(define (agent-skills-service)
  (simple-service 'agent-skills
                  home-activation-service-type
                  agent-skills-activation))
