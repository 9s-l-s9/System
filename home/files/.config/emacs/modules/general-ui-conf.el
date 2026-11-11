;;; general-ui-conf.el --- General UI improvements -*- lexical-binding: t -*-
;; Author: Samuel Schmidt
;;; Code:

;; No fringe but nice glyphs for truncated and wrapped lines
(fringe-mode '(0 . 0))
;; Note: global-visual-line-mode omitted — conflicts with header-line redisplay

;; General
(setq widget-image-enable nil)

;; Base font for everything (default face; header-line, minibuffer, etc. all
;; derive from it). iA Writer Mono, variable cut ("iA Writer Mono V") in its
;; "Text" instance: a touch heavier than Regular, which keeps light-on-dark
;; strokes from looking thin.  Packaged in home/packages/font-ia-writer.scm.
;; Fontconfig name: "-14" is the size in points.  C-x C-+ still scales
;; buffer text on top of this.
;;
;; Under `emacs --daemon' there is no graphical display while init runs, so
;; a `:font' set on the default face never reaches the template for new
;; frames: `emacsclient -c' frames fell back to Emacs's built-in ~10 pt font.
;; `default-frame-alist' is applied to every new frame, daemon or not; the
;; face call covers the initial frame of a non-daemon Emacs.
(defconst sls-default-font "iA Writer Mono V-14:style=Text"
  "Fontconfig name of the base font for every frame.")
(add-to-list 'default-frame-alist `(font . ,sls-default-font))
(unless (daemonp)
  (set-face-attribute 'default nil :font sls-default-font))

;; Indentation lines
;; `bitmap' is the cheapest method; `character' re-fontifies noticeably on
;; every edit in large buffers.  `responsive' nil skips per-cursor-move work.
(setq highlight-indent-guides-method 'bitmap
      highlight-indent-guides-responsive nil
      highlight-indent-guides-auto-character-face-perc 70)

(global-hl-line-mode +1)
(setq hl-line-sticky-flag nil
      global-hl-line-sticky-flag nil)

;; Theme — "Tafelgrün": chalk on a near-black blackboard green, after the
;; Faber-Castell 9000 (lacquer green, gold stamping, steel ferrule).  A
;; Nano-style hierarchy with one role per hue:
;;   chalk   text, variables, constants      strong  definitions, headings (weight)
;;   yellow  keywords (structure)            orange  literals: strings, code, TODO
;;   steel   types, builtins                 graphite comments, docstrings
;; Errors, warnings, and diffs keep their own red/green/yellow.
;;
;; Palette overrides must be set BEFORE `load-theme'; this is the
;; supported way to retint a Modus theme without forking it.
;; See: https://protesilaos.com/emacs/modus-themes#h:a897b85e-d7d8-43c2-9420-cb615b21fb58
(setq modus-themes-italic-constructs t          ; comments/docstrings in italic — paper feel
      modus-themes-bold-constructs   nil
      modus-themes-headings          '((t . (semibold)))
      modus-themes-common-palette-overrides
      '(;; Semantic colors for diagnostics and diffs.
        (red "#d47b75") (red-warmer "#d47b75") (red-cooler "#d47b75")
        (red-faint "#ad8582") (red-intense "#df8b85")
        (green "#93a88b") (green-warmer "#93a88b") (green-cooler "#93a88b")
        (green-faint "#879780") (green-intense "#a3b89b")
        (yellow "#c3a77a") (yellow-warmer "#c3a77a") (yellow-cooler "#c3a77a")
        (yellow-faint "#a39885") (yellow-intense "#d3b78a")
        ;; Modus uses these families for ordinary links, mail fields, and
        ;; navigation.  Keep those in chalk as well as the syntax tokens.
        (blue "#c2bcac") (blue-warmer "#c2bcac") (blue-cooler "#c2bcac")
        (blue-faint "#9b968a") (blue-intense "#dad4c4")
        (magenta "#c2bcac") (magenta-warmer "#c2bcac") (magenta-cooler "#c2bcac")
        (magenta-faint "#9b968a") (magenta-intense "#dad4c4")
        (cyan "#c2bcac") (cyan-warmer "#c2bcac") (cyan-cooler "#c2bcac")
        (cyan-faint "#9b968a") (cyan-intense "#dad4c4")
        ;; diff / change backgrounds — subtle dark tints, no neon
        (bg-added     "#11211a") (bg-added-refine   "#1a3328")
        (bg-removed   "#241414") (bg-removed-refine "#3a1c1c")
        (bg-changed   "#221d10") (bg-changed-refine "#332b14")
        (fg-added "#93a88b") (fg-removed "#d47b75") (fg-changed "#c3a77a")
        ;; ── surfaces & structure: blackboard green ────────────
        (bg-main      "#0c100d")   ; near-black with a green cast
        (bg-dim       "#080b09")
        (fg-main      "#dad4c4")   ; chalk
        (fg-dim       "#9b968a")   ; chalk dust
        (bg-hl-line   "#141b15")   ; whisper-quiet current-line wash
        (bg-region    "#2a2a20")
        (fg-region    unspecified)
        (cursor       "#dad4c4")
        ;; hairline line numbers, muted active gutter
        (fg-line-number-inactive "#2e352e")
        (fg-line-number-active   "#9b968a")
        (bg-line-number-inactive "#0c100d")
        (bg-line-number-active   "#0c100d")
        ;; quiet the mode-line border chrome
        (border-mode-line-active   "#dad4c4")
        (border-mode-line-inactive "#2a2a20")
        ;; ── syntax: one role per hue ──────────────────────────
        (comment      "#6e6c62")   ; graphite, italic
        (docstring    "#6e6c62")
        (docmarkup    "#9b968a")
        (string       "#e0823f")   ; orange: literals
        (keyword      "#e2d29e")   ; chalk yellow: structure
        (builtin      "#9eaab3")   ; steel
        (fnname       "#dad4c4")   ; chalk, semibold via `sls-tafel-weights'
        (type         "#9eaab3")   ; steel
        (variable     "#dad4c4")
        (constant     "#dad4c4")
        (preprocessor "#9b968a")
        (rx-construct "#e2d29e")
        (rx-backslash "#e2d29e")
        ;; prose: inline code is the string of running text
        (prose-code     "#e0823f")
        (prose-verbatim "#e0823f")
        (prose-todo     "#e0823f")
        (prose-done     "#6e6c62")
        ;; Links remain identifiable through underlines.
        (fg-heading-0 fg-main) (fg-heading-1 "#e2d29e")
        (fg-heading-2 fg-main) (fg-heading-3 fg-main)
        (fg-heading-4 fg-dim) (fg-heading-5 fg-dim)
        (fg-heading-6 fg-dim) (fg-heading-7 fg-dim) (fg-heading-8 fg-dim)
        (fg-link      "#dad4c4")
        (underline-link "#6e6c62")))

;; Definitions carry weight instead of a colour of their own.  Theme loads
;; reset face attributes, so reapply on every enabled theme.
(defun sls-tafel-weights (&rest _)
  "Set function names in semibold."
  (set-face-attribute 'font-lock-function-name-face nil :weight 'semibold))
(add-hook 'enable-theme-functions #'sls-tafel-weights)

(load-theme 'modus-vivendi t)
(setq custom-safe-themes t)

;; Emoji: prefer a real color emoji font when present; fall back silently.
(when (member "Noto Color Emoji" (font-family-list))
  (set-fontset-font t 'emoji "Noto Color Emoji" nil 'prepend))

;; Visual pulse on focus change (built-in beacon alternative)
;; https://karthinks.com/software/batteries-included-with-emacs/
(defun pulse-line (&rest _)
  "Pulse the current line."
  (pulse-momentary-highlight-one-line (point)))

(dolist (command '(scroll-up-command scroll-down-command
                                     recenter-top-bottom other-window))
  (advice-add command :after #'pulse-line))

;; Line spacing
(setq-default line-spacing 2)
;; Underline at descent position, not baseline
(setq x-underline-at-descent-line t)

;; Cursor shape is owned by Meow (per modal state); we only disable blink.
(blink-cursor-mode 0)

(show-paren-mode t)

;; Absolute line numbers: relative numbers re-render the whole gutter on every
;; line change, which is a measurable per-keystroke cost under PGTK.
(setq display-line-numbers-grow-only        t
      display-line-numbers-type             t
      display-line-numbers-width            4
      display-line-numbers-width-start      t)
(global-display-line-numbers-mode 1)

(provide 'general-ui-conf)
;;; general-ui-conf.el ends here
