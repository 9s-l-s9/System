;;; valsi-conf.el --- VALSI artifact application -*- lexical-binding: t -*-
;;; Code:

(add-to-list 'load-path "~/Projects/valsi/lisp/")
(require 'valsi)
(valsi-global-mode 1)     ; auto-activates the right grammar per file

;; Meow integration: let meow own the modal state machine.  VALSI's Browse
;; becomes a dedicated meow state driven by `valsi-browse-mode-map' (so its
;; keys work at emulation priority instead of being shadowed by NORMAL),
;; and VALSI's Insert hands the buffer to meow NORMAL -- the modal editing
;; home -- rather than to meow insert.  Return to Browse with SPC n (leader).
(with-eval-after-load 'meow
  (meow-define-state valsi
    "Meow state driving VALSI's semantic Browse commands."
    :lighter " [VALSI]"
    :keymap valsi-browse-mode-map)

  (defun sls-valsi-meow-browse ()
    "Mirror VALSI's Browse state as the meow `valsi' state."
    (when (bound-and-true-p meow-mode)
      (meow--switch-state 'valsi)))

  (defun sls-valsi-meow-insert ()
    "Mirror VALSI's Insert state as meow NORMAL for modal editing."
    (when (bound-and-true-p meow-mode)
      (meow--switch-state 'normal)))

  (add-hook 'valsi-enter-browse-hook #'sls-valsi-meow-browse)
  (add-hook 'valsi-enter-insert-hook #'sls-valsi-meow-insert)

  ;; Cover both enable orders on `find-file': when meow initializes the
  ;; buffer after VALSI already entered Browse, re-assert the valsi state.
  (defun sls-valsi-meow-sync ()
    (when (and (bound-and-true-p valsi-artifact-minor-mode)
               (eq (bound-and-true-p valsi--interaction-state) 'browse))
      (meow--switch-state 'valsi)))
  (add-hook 'meow-mode-hook #'sls-valsi-meow-sync))

(provide 'valsi-conf)
;;; valsi-conf.el ends here
