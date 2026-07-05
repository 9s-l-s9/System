(define-module (services agent-skills)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (agent-skills-service))

(define agent-skills-activation
  #~(begin
      (use-modules (guix build utils)
                   (ice-9 format))

      (define home (getenv "HOME"))
      (define target (string-append home "/Projects/System/.agents/skills"))

      (define (ensure-live-skills-link link)
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

      (unless (file-exists? target)
        (format (current-error-port)
                "agent-skills: source directory does not exist: ~a~%"
                target)
        (exit 1))

      ;; Codex, OpenCode, and Pi support ~/.agents/skills.  Claude Code
      ;; uses ~/.claude/skills, so link it to the same canonical tree.
      (ensure-live-skills-link (string-append home "/.agents/skills"))
      (ensure-live-skills-link (string-append home "/.claude/skills"))))

(define (agent-skills-service)
  (simple-service 'agent-skills
                  home-activation-service-type
                  agent-skills-activation))
