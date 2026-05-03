;;; dap-conf.el --- Debug Adapter Protocol via dap-mode -*- lexical-binding: t -*-
;;; Code:

(require 'dap-mode)

;; ── Core settings ─────────────────────────────────────────────────────────────

(setq dap-auto-configure-features '(sessions locals controls tooltip)
      dap-print-io nil)             ; quiet logging

;; Show variable values inline in the source buffer
(add-hook 'dap-stopped-hook #'dap-hydra)

;; ── Python / debugpy ──────────────────────────────────────────────────────────

(require 'dap-python)

;; Use the system-installed debugpy (from python-debugpy Guix package)
(setq dap-python-debugger    'debugpy
      dap-python-executable  "python3")

;; Debug templates
(dap-register-debug-template
 "Python: Current File"
 (list :type    "python"
       :request "launch"
       :name    "Python: Current File"
       :program "${file}"
       :console "integratedTerminal"))

(dap-register-debug-template
 "Python: Module"
 (list :type    "python"
       :request "launch"
       :name    "Python: Module"
       :module  "${input:module}"
       :console "integratedTerminal"))

(dap-register-debug-template
 "Python: pytest (all)"
 (list :type    "python"
       :request "launch"
       :name    "Python: pytest"
       :module  "pytest"
       :args    ["-v"]
       :console "integratedTerminal"))

(dap-register-debug-template
 "Python: pytest (current file)"
 (list :type    "python"
       :request "launch"
       :name    "Python: pytest file"
       :module  "pytest"
       :args    ["${file}" "-v"]
       :console "integratedTerminal"))

;; ── Keybindings ───────────────────────────────────────────────────────────────

;; C-c d prefix for all debug actions
(global-set-key (kbd "C-c d d") #'dap-debug)
(global-set-key (kbd "C-c d b") #'dap-breakpoint-toggle)
(global-set-key (kbd "C-c d B") #'dap-breakpoint-condition)
(global-set-key (kbd "C-c d c") #'dap-continue)
(global-set-key (kbd "C-c d n") #'dap-next)
(global-set-key (kbd "C-c d i") #'dap-step-in)
(global-set-key (kbd "C-c d o") #'dap-step-out)
(global-set-key (kbd "C-c d r") #'dap-restart-frame)
(global-set-key (kbd "C-c d q") #'dap-disconnect)
(global-set-key (kbd "C-c d l") #'dap-ui-locals)
(global-set-key (kbd "C-c d s") #'dap-ui-sessions)
(global-set-key (kbd "C-c d e") #'dap-eval-thing-at-point)

(provide 'dap-conf)
;;; dap-conf.el ends here
