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
;; This module is GUARDED: if `eca' isn't installed yet it does nothing, so it
;; can sit in init.el while you finish pinning the Guix package.
;;; Code:

(when (require 'eca nil t)

  ;; ── Server command ──────────────────────────────────────────────────────────
  ;; Uncomment + adapt once you have a server jar.  Leaving this unset lets
  ;; eca-emacs fall back to its own auto-download behaviour.
  ;;
  ;; (setq eca-custom-command
  ;;       '("java" "-jar" "~/.local/share/eca/eca.jar" "server"))

  ;; Start/focus a session via the meow leader (SPC e), set in keybindings-conf.
  (with-eval-after-load 'eca
    (when (boundp 'eca-mode-map)
      (define-key eca-mode-map (kbd "C-c C-k") #'eca-stop))))

(provide 'eca-conf)
;;; eca-conf.el ends here
