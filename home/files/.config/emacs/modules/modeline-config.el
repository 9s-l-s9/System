;;; modeline-config.el --- Minimal header-line modeline -*- lexical-binding: t -*-
;;
;; Inspired by elegant-emacs (github.com/rougier/elegant-emacs).
;; Modeline moves to the TOP of each window (header-line).
;; Shows: buffer name + modified · major mode · git branch.
;; Bottom mode-line is made invisible; windows are separated by a 3-px divider.
;; A 24-px internal border creates clean margins that include the line-number gutter.
;;; Code:

;; ── Render helper ─────────────────────────────────────────────────────────────

(defun sls-mode-line-render (left right)
  "Render LEFT flush-left and RIGHT flush-right to fill the window width."
  (concat left
          (propertize " " 'display
                      `(space :align-to (- right ,(length right))))
          right))

;; ── Git branch ────────────────────────────────────────────────────────────────

(defun sls-mode-line-vc ()
  "Return the current git branch name, or nil."
  (when (and vc-mode (string-match "Git[-: ]\\(.+\\)" vc-mode))
    (string-trim (match-string 1 vc-mode))))

;; ── Format spec ───────────────────────────────────────────────────────────────

(defvar sls-header-line-format
  '((:eval
     (sls-mode-line-render
      ;; Left: buffer name + optional (modified) marker
      (format-mode-line
       (list " "
             (propertize "%b" 'face 'mode-line-buffer-id)
             (when (and buffer-file-name (buffer-modified-p))
               (propertize " (modified)" 'face 'shadow))))
      ;; Right: major mode  git branch
      (format-mode-line
       (list (propertize "%m" 'face 'shadow)
             (when-let ((branch (sls-mode-line-vc)))
               (propertize (concat "  " branch) 'face 'shadow))
             " ")))))
  "Header-line format: buffer name, major mode, git branch.")

(setq-default header-line-format sls-header-line-format)
;; Remove the bottom mode-line entirely — `window-divider-mode` draws the
;; visible bottom separator line instead. Shrinking mode-line via :height
;; doesn't actually collapse the row, so the theme bg leaks through as a block.
(setq-default mode-line-format nil)

;; `setq-default` only affects buffers that haven't set the variable locally.
;; Many modes (imenu-list, dired, ibuffer, magit, …) bind `mode-line-format`
;; in their own buffers, so wipe it whenever a buffer's major mode is set.
(defun sls--kill-local-mode-line ()
  (kill-local-variable 'mode-line-format)
  (setq mode-line-format nil))
(add-hook 'after-change-major-mode-hook #'sls--kill-local-mode-line)
;; Apply to buffers that already exist at load time.
(dolist (buf (buffer-list))
  (with-current-buffer buf (sls--kill-local-mode-line)))

;; ── Window dividers ───────────────────────────────────────────────────────────
;; Bottom dividers replace the mode-line as the per-window bottom separator.
;; Right dividers separate side-by-side splits.

(setq window-divider-default-right-width  3
      window-divider-default-bottom-width 1
      window-divider-default-places       t)
(window-divider-mode 1)

;; ── Face styling ──────────────────────────────────────────────────────────────

(defun sls-set-modeline-faces (&rest _)
  "Apply elegant-emacs-style faces: header-line info bar + thin bottom line."
  ;; Header-line: blends with buffer background; underline separates it from text
  (set-face-attribute 'header-line nil
                      :underline  (face-foreground 'default)
                      :foreground (face-foreground 'default)
                      :background (face-background 'default)
                      :box        nil
                      :inherit    nil)
  ;; Window divider provides the visible separator lines (top/right/bottom).
  (set-face-attribute 'window-divider nil
                      :foreground (face-foreground 'default))
  (set-face-attribute 'window-divider-first-pixel nil
                      :foreground (face-background 'default))
  (set-face-attribute 'window-divider-last-pixel nil
                      :foreground (face-background 'default)))

(add-hook 'after-init-hook #'sls-set-modeline-faces)
;; Re-apply whenever the user switches theme at runtime
(advice-add 'load-theme :after #'sls-set-modeline-faces)

;; ── Margins (internal border) ─────────────────────────────────────────────────
;;
;; internal-border-width offsets ALL window content — including the line-number
;; margin — from the frame edge, so relative line numbers stay inside the margin.

(defun sls-set-frame-margins (&optional frame)
  "Set 24-px internal border on FRAME (or current frame)."
  (set-frame-parameter (or frame (selected-frame))
                       'internal-border-width 24))

(sls-set-frame-margins)
(add-hook 'after-make-frame-functions #'sls-set-frame-margins)

(provide 'modeline-config)
;;; modeline-config.el ends here
