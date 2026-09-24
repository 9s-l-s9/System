;;; keybindings-conf.el --- Meow modal keybindings -*- lexical-binding: t -*-
;;; Code:

;; Leader keys meow's keypad reserves and never passes through:
;;   m -> M-   g -> C-M-   SPC -> literal   c/h/x -> C-c/C-h/C-x prefixes
;; So SPC m / SPC c never reach a leader command.  SPC c c is C-c C-c
;; (send mail, org confirm), so the C-c prefix stays as it is.

;; App launcher: SPC o <key>.  Apps live only here, not on the leader.
(defvar-keymap sls-apps-map
  :doc "Start an app (SPC o)."
  "m" #'notmuch                 ; mail
  "c" #'sls-config-jump         ; any file in ~/Projects/System
  "v" #'magit-status
  "t" #'eat
  "d" #'dired
  "i" #'ibuffer
  "a" #'gptel
  "e" #'eca
  "n" #'valsi)
(fset 'sls-apps-map sls-apps-map)

(defun meow-setup ()
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (meow-motion-overwrite-define-key
   '("n" . meow-next)
   '("p" . meow-prev)
   '("<escape>" . ignore))
  (meow-leader-define-key
   '("o" . sls-apps-map)       ; apps: SPC o m mail, SPC o v magit, SPC o c config ...
   ;; Navigation panels (all open in right side window)
   '("d" . sls-dired-sidebar-toggle)
   '("s" . imenu-list-smart-toggle)
   '("r" . sls-recentf-open)
   '("b" . bookmark-bmenu-list)
   ;; Actions
   '("p" . sls-new-entry-pkb)
   '("E" . sls-export-org-to-html-and-pdf)
   '("T" . sls-capture-todo)       ; quick-capture to the shared wm.org inbox
   '("y" . sls-copy-file-path)
   '("R" . sls-reload-init-file) ; reload config in place (no daemon restart)
   '("u" . vundo)              ; visual undo tree
   '("f" . delete-other-windows) ;focus
   ;; AI (the gptel chat itself is SPC o a)
   '("A" . gptel-menu)
   ;; '("c" . minuet-show-suggestion) ; inline completion; needs an API key
   '("w" . whisper-run))       ; voice to text (dictation)

  (meow-normal-define-key
   '("0" . meow-expand-0)
   '("9" . meow-expand-9)
   '("8" . meow-expand-8)
   '("7" . meow-expand-7)
   '("6" . meow-expand-6)
   '("5" . meow-expand-5)
   '("4" . meow-expand-4)
   '("3" . meow-expand-3)
   '("2" . meow-expand-2)
   '("1" . meow-expand-1)
   '("-" . negative-argument)
   '(";" . meow-reverse)
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("[" . meow-beginning-of-thing)
   '("]" . meow-end-of-thing)
   '("a" . avy-goto-char-2)
   '("A" . meow-open-below)
   '("b" . meow-back-word)
   '("B" . meow-back-symbol)
   '("c" . copy-region-as-kill)
   '("d" . meow-delete)
   '("D" . meow-backward-delete)
   '("e" . meow-next-word)
   '("E" . meow-next-symbol)
   '("f" . sudo-edit-find-file)
   '("F" . meow-find)
   '("G" . meow-cancel-selection)
   '("g" . meow-grab)
   '("i" . meow-insert)
   '("I" . meow-open-above)
   '("j" . meow-prev)
   '("J" . meow-prev-expand)
   '("k" . meow-next)
   '("K" . meow-next-expand)
   '("l" . meow-left)
   '("L" . meow-left-expand)
   '("r" . meow-right)
   '("R" . meow-right-expand)
   '("m" . execute-extended-command)
   '("o" . meow-block)
   '("O" . meow-to-block)
   '("p" . meow-yank)
   '("q" . meow-quit)
   '("Q" . meow-goto-line)
   '("s" . meow-kill)
   '("t" . meow-till)
   '("u" . meow-undo)
   '("U" . meow-undo-in-selection)
   '("v" . meow-visit)
   '("w" . meow-mark-word)
   '("W" . meow-mark-symbol)
   '("x" . meow-line)
   '("X" . meow-goto-line)
   '("y" . meow-save)
   '("Y" . meow-sync-grab)
   '("z" . meow-pop-selection)
   '("ß" . comment-or-uncomment-region)
   '("'" . repeat)
   '("<escape>" . ignore)))

;; Defer activation: even if `meow' is loaded later, bindings install once
;; it appears, so we don't depend on `init.el' load order.
(with-eval-after-load 'meow
  (meow-setup)
  (meow-global-mode 1))
(require 'meow)

;; ── dap-mode: debugging (C-c C-d prefix) ────────────────────────────────────
;; `meow-leader-define-key' installs the leader into `mode-specific-map',
;; so `C-c d' is already the dired sidebar toggle (SPC d).  Use C-c C-d.
(global-set-key (kbd "C-c C-d d") #'dap-debug)
(global-set-key (kbd "C-c C-d b") #'dap-breakpoint-toggle)
(global-set-key (kbd "C-c C-d B") #'dap-breakpoint-condition)
(global-set-key (kbd "C-c C-d c") #'dap-continue)
(global-set-key (kbd "C-c C-d n") #'dap-next)
(global-set-key (kbd "C-c C-d i") #'dap-step-in)
(global-set-key (kbd "C-c C-d o") #'dap-step-out)
(global-set-key (kbd "C-c C-d r") #'dap-restart-frame)
(global-set-key (kbd "C-c C-d q") #'dap-disconnect)
(global-set-key (kbd "C-c C-d l") #'dap-ui-locals)
(global-set-key (kbd "C-c C-d s") #'dap-ui-sessions)
(global-set-key (kbd "C-c C-d e") #'dap-eval-thing-at-point)

;; ── gptel: chat / rewrite ───────────────────────────────────────────────────
;; Chat is SPC o a, the menu SPC A (meow leader); `C-c a' / `C-c A' are
;; intentionally not bound here to avoid duplicating those.
(global-set-key (kbd "C-c RET") #'gptel-send)
(global-set-key (kbd "C-c C-a") #'gptel-add)
(global-set-key (kbd "C-c C-r") #'gptel-rewrite)

;; ── helpful: better describe-* commands ──────────────────────────────────────
(global-set-key [remap describe-command] #'helpful-command)
(global-set-key [remap describe-function] #'helpful-callable)
(global-set-key [remap describe-key] #'helpful-key)
(global-set-key [remap describe-symbol] #'helpful-symbol)
(global-set-key [remap describe-variable] #'helpful-variable)
(global-set-key (kbd "C-h F") #'helpful-function)

;; ── window-conf: winner-mode (undo/redo window layouts) ─────────────────────
(global-set-key (kbd "C-c <left>")  #'winner-undo)
(global-set-key (kbd "C-c <right>") #'winner-redo)

(provide 'keybindings-conf)
;;; keybindings-conf.el ends here
