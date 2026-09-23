(define-module (services claude)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (claude-service))

;; Declarative Claude Code settings, shared by every machine that runs this
;; home configuration.  They are installed as
;; ~/.config/claude-code/settings.json and handed to the CLI with
;; `--settings' by scripts/claude-guix.scm.  Flag settings sit above the
;; user settings in precedence, so they win over ~/.claude/settings.json,
;; which stays mutable for the state Claude Code writes itself (theme,
;; effort, accepted dialogs).
;;
;; Checked against Claude Code 2.1.280 (2026-09-22).
;;
;; - $schema: the published JSON schema, for editor completion and
;;   validation.  It may lag behind the newest releases, so a warning on a
;;   freshly documented key does not mean the file is wrong.
;; - CLAUDE_CODE_SUBAGENT_MODEL: subagents, teammates and workflow agents
;;   default to Sonnet instead of inheriting the (expensive) main model.
;;   Since 2.1.251 this is only a default: a model Claude passes when it
;;   spawns the agent and a `model' field in the agent definition both win,
;;   so a per-agent choice stays possible.  CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1
;;   (2.1.257+) would restore the old behaviour of overriding both.
;; - permissions.ask Agent: spawning a subagent always prompts.  An explicit
;;   ask rule is one of the few things no permission mode auto-approves,
;;   bypassPermissions included, so the prompt appears even though the
;;   launcher starts the CLI with --dangerously-skip-permissions.  (Allow
;;   rules, by contrast, have no effect in that mode; deny rules always do.)
(define claude-settings
  (plain-file
   "claude-code-settings.json"
   "{
  \"$schema\": \"https://json.schemastore.org/claude-code-settings.json\",
  \"env\": {
    \"CLAUDE_CODE_SUBAGENT_MODEL\": \"sonnet\"
  },
  \"permissions\": {
    \"ask\": [
      \"Agent\"
    ]
  }
}
"))

(define claude-service-type
  (service-type
   (name 'claude-code)
   (extensions
    (list
     (service-extension home-xdg-configuration-files-service-type
                        (lambda (_)
                          `(("claude-code/settings.json" ,claude-settings))))))
   (default-value #f)
   (description "Install declarative Claude Code settings.")))

(define (claude-service)
  (service claude-service-type))
