;;; modeline-conf.el --- Minimal header-line modeline -*- lexical-binding: t -*-
;;
;; Inspired by elegant-emacs (github.com/rougier/elegant-emacs).
;; Modeline moves to the TOP of each window (header-line).
;; Shows: buffer name + modified · major mode · git branch.
;; Bottom mode-line is made invisible; windows are separated by a 3-px divider.
;; A 24-px internal border creates clean margins that include the line-number gutter.
;;; Code:

;; ── Render helper ─────────────────────────────────────────────────────────────

(defun sls-mode-line-render (left right)
  "Render LEFT flush-left and RIGHT flush-right to fill the window width.
Uses pixel width so alignment stays correct with icons or wide chars."
  (let ((right-px (string-pixel-width right)))
    (concat left
            (propertize " " 'display
                        `(space :align-to (- right (,right-px))))
            right)))

;; ── Git branch ────────────────────────────────────────────────────────────────

(defun sls-mode-line-vc ()
  "Return the current git branch name, or nil."
  (when (and vc-mode (string-match "Git[-: ]\\(.+\\)" vc-mode))
    (string-trim (match-string 1 vc-mode))))

;; ── Format spec ───────────────────────────────────────────────────────────────

(defvar sls-header-line-format
  '((:eval
     (sls-mode-line-render
      ;; Left: buffer name + optional (modified) marker.
      ;; No leading/trailing pad chars — the modeline text starts at the same
      ;; pixel as the buffer text so both align on the window edge.
      (format-mode-line
       (list (propertize "%b" 'face 'mode-line-buffer-id)
             (when (and buffer-file-name (buffer-modified-p))
               (propertize " (modified)" 'face 'shadow))))
      ;; Right: major mode  git branch
      (format-mode-line
       (list (propertize "%m" 'face 'shadow)
             (when-let ((branch (sls-mode-line-vc)))
               (propertize (concat "  " branch) 'face 'shadow)))))))
  "Header-line format: buffer name, major mode, git branch.")

(setq-default header-line-format sls-header-line-format)
;; The bottom mode-line becomes an invisible short spacer row (" " with a
;; shrunken bg-colored face, see `sls-set-modeline-faces') so the buffer text
;; doesn't touch the bottom window divider. `window-divider-mode' draws the
;; visible separator line below it.
(setq-default mode-line-format " ")

;; `setq-default` only affects buffers that haven't set the variable locally.
;; Many modes (imenu-list, dired, ibuffer, magit, …) bind `mode-line-format`
;; in their own buffers, so wipe it whenever a buffer's major mode is set.
(defun sls--kill-local-mode-line ()
  (kill-local-variable 'mode-line-format)
  (setq mode-line-format " "))
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

(defun sls--default-color (attr frame)
  "Return the default face ATTR (:foreground/:background) on FRAME as a real
color string, or nil when it is still unspecified.

On a daemon the initial frame is a TTY, where these attributes are the literal
placeholders \"unspecified-fg\"/\"unspecified-bg\".  Baking those into a box or
underline color makes Emacs render them as a stray white line, so callers must
skip styling until a real (graphical) color is available."
  (let ((c (face-attribute 'default attr frame t)))
    (and (stringp c)
         (not (string-prefix-p "unspecified" c))
         c)))

(defun sls-set-modeline-faces (&rest args)
  "Apply elegant-emacs-style faces: header-line info bar + thin bottom line.
When called from a frame hook ARGS may carry the new FRAME; otherwise the
selected frame is used.  Colors are resolved from that frame and the function
bails out on a TTY where they are unspecified (see `sls--default-color')."
  (let* ((frame (or (car (seq-filter #'framep args)) (selected-frame)))
         (bg (sls--default-color :background frame))
         (fg (sls--default-color :foreground frame)))
    (when (and bg fg)
      ;; Header-line: blends with buffer background; underline separates it from
      ;; text.  The background-colored box adds 10 px vertical padding without a
      ;; visible border (nano-emacs trick; Emacs rejects a 0 horizontal width,
      ;; and the 1 px edge is invisible on the matching background). :position 5
      ;; floats the underline mid-padding: ~5 px air between text and rule, ~5 px
      ;; between rule and the first buffer line.
      (set-face-attribute 'header-line nil
                          :underline  `(:color ,fg :position 5)
                          :foreground fg
                          :background bg
                          :box        `(:line-width (1 . 10) :color ,bg)
                          :inherit    nil)
      ;; Emacs 31 draws non-selected windows with `header-line-inactive';
      ;; style it to match so headers don't flip colors on focus change.
      (when (facep 'header-line-inactive)
        (set-face-attribute 'header-line-inactive nil
                            :underline  `(:color ,fg :position 5)
                            :foreground (face-foreground 'shadow nil t)
                            :background bg
                            :box        `(:line-width (1 . 10) :color ,bg)
                            :inherit    nil))
      ;; Bottom mode-line is a short invisible spacer (format is " "): shrink it
      ;; and paint it buffer-background so it reads as padding above the divider.
      (dolist (face '(mode-line mode-line-inactive mode-line-active))
        (when (facep face)
          (set-face-attribute face nil
                              :height     0.35
                              :box        nil
                              :underline  nil
                              :overline   nil
                              :foreground bg
                              :background bg
                              :inherit    nil)))
      ;; Window divider provides the visible separator lines (top/right/bottom).
      (set-face-attribute 'window-divider nil :foreground fg)
      (set-face-attribute 'window-divider-first-pixel nil :foreground bg)
      (set-face-attribute 'window-divider-last-pixel nil :foreground bg))))

(add-hook 'after-init-hook #'sls-set-modeline-faces)
;; Re-apply once a real (graphical) frame exists — critical under the daemon,
;; whose initial TTY frame has unspecified colors that must not be baked in.
;; `sls-set-modeline-faces' takes the new FRAME via its &rest ARGS, so
;; `after-make-frame-functions' (which passes FRAME) is the right hook;
;; `server-after-make-frame-hook' (which passes nothing) would be redundant.
(add-hook 'after-make-frame-functions #'sls-set-modeline-faces)
;; Re-apply whenever the user switches theme at runtime
(advice-add 'load-theme :after #'sls-set-modeline-faces)

;; ── Minibuffer top padding ────────────────────────────────────────────────────
;; The minibuffer/echo-area text otherwise touches the window divider above it.
;; A shrunken invisible header-line acts as top padding. :inherit unspecified
;; keeps it from picking up the header-line face's underline.

(defun sls--minibuffer-pad ()
  "Give the current (mini)buffer a short invisible header-line as top padding."
  (let ((bg (sls--default-color :background (selected-frame))))
    (when bg
      (setq header-line-format
            (propertize " " 'face (list :height 0.3 :underline nil :box nil
                                        :background bg
                                        :inherit 'unspecified))))))
(add-hook 'minibuffer-setup-hook #'sls--minibuffer-pad)

(defun sls--minibuffer-pad-refresh-all ()
  "Re-pad every live (mini)buffer and echo-area buffer.
Bound to `server-after-make-frame-hook', which runs with no FRAME argument
\(unlike `after-make-frame-functions'\), because `sls--minibuffer-pad' takes
none either — the daemon's first real frame is when `face-background'
finally resolves to a real color instead of \"unspecified-bg\"."
  (dolist (buf (buffer-list))
    (when (or (minibufferp buf)
              (string-prefix-p " *Echo Area" (buffer-name buf)))
      (with-current-buffer buf (sls--minibuffer-pad)))))
(add-hook 'server-after-make-frame-hook #'sls--minibuffer-pad-refresh-all)
;; Also pad buffers that already exist at load time (non-daemon startup).
(sls--minibuffer-pad-refresh-all)

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

(provide 'modeline-conf)
;;; modeline-conf.el ends here
