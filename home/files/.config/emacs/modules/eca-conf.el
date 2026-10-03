;;; eca-conf.el --- Autonomous AI agent via ECA -*- lexical-binding: t -*-
;;; Commentary:
;; ECA (Editor Code Assistant) is the autonomous-agent counterpart to gptel:
;; gptel keeps you in the loop for chat/rewrite; ECA runs a full agent loop
;; (reads files, runs tools, edits the repo, iterates).
;;
;; The Emacs package (emacs-eca) is the CLIENT.  It needs the ECA SERVER:
;;   - Easiest: let eca-emacs auto-download a native server build the first
;;     time you call `eca'.  On Guix a downloaded native binary may not run
;;     (no FHS dynamic linker), so prefer the JVM route below.
;;   - Guix-friendly: run the server jar with the openjdk in your profile.
;;     Set `eca-custom-command' to your `java -jar /path/to/eca.jar server'
;;     invocation once you have the jar (release asset from the eca repo).
;;
;; `eca' is autoloaded, so this module never needs to load the package
;; eagerly; the settings below only apply once `eca' is actually invoked
;; (via the meow app launcher, SPC o e, set in keybindings-conf.el).
;;; Code:

;; Optional server override:
;; (setq eca-custom-command '("java" "-jar" "~/.local/share/eca/eca.jar" "server"))

;; Preserve ECA's native model/agent header; move progress and trust status
;; into the common top header instead of resurrecting a bottom mode line.
(setq eca-chat-override-mode-line nil
      eca-chat-mode-line-format '(:init-progress :elapsed-time " " :usage " " :trust))

(defun sls-eca-ui-setup ()
  (setq-local sls-ui-title "AI / agent"
              mode-line-process
              '(:eval (when-let* ((session (eca-session)))
                        (eca-chat--mode-line-string session)))
              sls-ui-actions '(("Send prompt" . eca-chat-send-prompt-at-chat)
                               ("Stop response" . eca-chat-stop-prompt)
                               ("New chat" . eca-chat-new)
                               ("Choose chat…" . eca-chat-select)
                               ("Choose model…" . eca-chat-select-model)
                               ("Show context" . eca-chat-show-context))))
(add-hook 'eca-chat-mode-hook #'sls-eca-ui-setup)

(provide 'eca-conf)
;;; eca-conf.el ends here
