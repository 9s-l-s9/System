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

(defvar-keymap sls-panels-map
  :doc "Manage the shared sidebar (SPC v)."
  "b" #'sls-side-panel-select-buffer
  "p" #'sls-side-panel-pin
  "o" #'sls-side-panel-pop-out
  "f" #'sls-side-panel-focus
  "q" #'sls-side-panel-hide
  "t" #'window-toggle-side-windows
  "u" #'winner-undo
  "r" #'winner-redo)
(fset 'sls-panels-map sls-panels-map)

(defun meow-setup ()
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (setf (alist-get 'valsi meow-replace-state-name-list) "BROWSE")
  ;; Read-only applications keep their native maps underneath Meow motion.
  ;; Editable buffers (including message composition and chats) use normal.
  (dolist (mode '(special-mode help-mode helpful-mode Info-mode
                  dired-mode ibuffer-mode bookmark-bmenu-mode
                  notmuch-hello-mode notmuch-search-mode notmuch-show-mode
                  notmuch-tree-mode magit-mode pdf-view-mode compilation-mode))
    (setf (alist-get mode meow-mode-state-list) 'motion))
  (dolist (mode '(message-mode notmuch-message-mode eca-chat-mode eat-mode))
    (setf (alist-get mode meow-mode-state-list) 'normal))
  (meow-motion-overwrite-define-key
   '("j" . sls-ui-previous)
   '("k" . sls-ui-next)
   '("l" . meow-left)
   '("r" . meow-right)
   '("RET" . sls-ui-open)
   '("q" . sls-ui-quit)
   '("<escape>" . ignore))
  (meow-leader-define-key
   '("o" . sls-apps-map)       ; apps: SPC o m mail, SPC o v magit, SPC o c config ...
   '("." . sls-ui-actions)
   '("\\" . sls-ui-native-key)
   '("RET" . sls-ui-open)
   '("e" . sls-ui-refresh)
   '("q" . sls-ui-quit)
   '("v" . sls-panels-map)
   ;; Navigation panels (all open in right side window)
   '("d" . sls-dired-sidebar-toggle)
   '("s" . sls-imenu-toggle)
   '("r" . sls-recentf-open)
   '("b" . sls-bookmarks-open)
   ;; Actions
   '("p" . sls-new-entry-pkb)
   '("E" . sls-export-org-to-html-and-pdf)
   '("T" . sls-capture-todo)       ; quick-capture to the shared wm.org inbox
   '("y" . sls-copy-file-path)
   '("R" . sls-reload-init-file) ; reload config in place (no daemon restart)
   '("u" . vundo)              ; visual undo tree
   '("f" . sls-window-focus)
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

;; VALSI's Browse state uses its semantic movement but the same directions
;; and leader as every other application.  `?' still opens its native menu.
(with-eval-after-load 'valsi
  (define-key valsi-browse-mode-map (kbd "SPC") #'meow-keypad)
  (define-key valsi-browse-mode-map (kbd "j") #'valsi-previous)
  (define-key valsi-browse-mode-map (kbd "k") #'valsi-next)
  (define-key valsi-browse-mode-map (kbd "l") #'meow-left)
  (define-key valsi-browse-mode-map (kbd "r") #'meow-right))

;; Enter activates the same action with or without Meow.  Keep these keys
;; here, including table rows whose text has no button/keymap property.
(dolist (entry '((sls-recentf-mode-map . sls-recentf-open-file)
                 (sls-imenu-mode-map . sls-imenu-open-item)))
  (when (boundp (car entry))
    (define-key (symbol-value (car entry)) (kbd "RET") (cdr entry))))

(with-eval-after-load 'helpful
  (define-key helpful-mode-map [remap revert-buffer] #'helpful-update))

(define-key minibuffer-local-map (kbd "M-A") #'marginalia-cycle)
(with-eval-after-load 'minuet
  (when (boundp 'minuet-active-mode-map)
    (define-key minuet-active-mode-map (kbd "M-RET") #'minuet-accept-suggestion)
    (define-key minuet-active-mode-map (kbd "C-g") #'minuet-dismiss-suggestion)
    (define-key minuet-active-mode-map (kbd "M-n") #'minuet-next-suggestion)
    (define-key minuet-active-mode-map (kbd "M-p") #'minuet-previous-suggestion)))

;; `which-key' is part of Emacs 30+; it documents the existing leader maps.
(when (require 'which-key nil t)
  (which-key-mode 1))

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
