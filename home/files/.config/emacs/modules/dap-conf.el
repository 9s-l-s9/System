;;; dap-conf.el --- Debug Adapter Protocol via dap-mode -*- lexical-binding: t -*-
;;; Code:

;; dap-mode is heavy (pulls lsp-mode, treemacs, hydra, posframe); load it
;; lazily on first use. `dap-debug' and friends are autoloaded, so the
;; keybindings in keybindings-conf.el work before this ever loads.
(with-eval-after-load 'dap-mode

  ;; ── Core settings ───────────────────────────────────────────────────────────

  (setq dap-auto-configure-features '(sessions locals controls tooltip)
        dap-print-io nil)             ; quiet logging

  ;; Show variable values inline in the source buffer
  (add-hook 'dap-stopped-hook #'dap-hydra)

  ;; ── Python / debugpy ────────────────────────────────────────────────────────

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
         :console "integratedTerminal")))

(provide 'dap-conf)
;;; dap-conf.el ends here
