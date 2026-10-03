;;; general-ui-conf.el --- General UI improvements -*- lexical-binding: t -*-
;; Author: Samuel Schmidt <samuel@schmidt-contact.com>
;;; Code:

;; No fringe but nice glyphs for truncated and wrapped lines
(fringe-mode '(0 . 0))
;; Note: global-visual-line-mode omitted — conflicts with header-line redisplay

;; General
(setq widget-image-enable nil)

;; Base font for everything (default face; header-line, minibuffer, etc. all
;; derive from it). iA Writer Mono (static cut, family "iA Writer Mono S"):
;; typewriter voice with modern Plex-derived metrics; packaged in
;; home/packages/font-ia-writer.scm. 1/10 pt units: 120 = 12 pt. C-x C-+
;; still scales buffer text on top of this.
(set-face-attribute 'default nil :family "iA Writer Mono S" :height 140)

;; Indentation lines
;; `bitmap' is the cheapest method; `character' re-fontifies noticeably on
;; every edit in large buffers.  `responsive' nil skips per-cursor-move work.
(setq highlight-indent-guides-method 'bitmap
      highlight-indent-guides-responsive nil
      highlight-indent-guides-auto-character-face-perc 70)

(global-hl-line-mode +1)
(setq hl-line-sticky-flag nil
      global-hl-line-sticky-flag nil)

;; Theme — Elegant/Nano-inspired hierarchy: primary ink, muted metadata,
;; quiet surfaces.  Color is reserved for errors, warnings, and changes.
;; Navigation and syntax use contrast, weight, and underlines.
;;
;; Palette overrides must be set BEFORE `load-theme'; this is the
;; supported way to retint a Modus theme without forking it.
;; See: https://protesilaos.com/emacs/modus-themes#h:a897b85e-d7d8-43c2-9420-cb615b21fb58
(setq modus-themes-italic-constructs t          ; comments/docstrings in italic — paper feel
      modus-themes-bold-constructs   nil
      modus-themes-common-palette-overrides
      '(;; Semantic colors for diagnostics and diffs.
        (red "#d47b75") (red-warmer "#d47b75") (red-cooler "#d47b75")
        (red-faint "#ad8582") (red-intense "#df8b85")
        (green "#93a88b") (green-warmer "#93a88b") (green-cooler "#93a88b")
        (green-faint "#879780") (green-intense "#a3b89b")
        (yellow "#c3a77a") (yellow-warmer "#c3a77a") (yellow-cooler "#c3a77a")
        (yellow-faint "#a39885") (yellow-intense "#d3b78a")
        ;; Modus uses these families for ordinary links, mail fields, and
        ;; navigation.  Keep those monochrome as well as the syntax tokens.
        (blue "#c4c4c4") (blue-warmer "#c4c4c4") (blue-cooler "#c4c4c4")
        (blue-faint "#9a9a9a") (blue-intense "#ededed")
        (magenta "#c4c4c4") (magenta-warmer "#c4c4c4") (magenta-cooler "#c4c4c4")
        (magenta-faint "#9a9a9a") (magenta-intense "#ededed")
        (cyan "#c4c4c4") (cyan-warmer "#c4c4c4") (cyan-cooler "#c4c4c4")
        (cyan-faint "#9a9a9a") (cyan-intense "#ededed")
        ;; diff / change backgrounds — subtle dark tints, no neon
        (bg-added     "#11211a") (bg-added-refine   "#1a3328")
        (bg-removed   "#241414") (bg-removed-refine "#3a1c1c")
        (bg-changed   "#221d10") (bg-changed-refine "#332b14")
        (fg-added "#93a88b") (fg-removed "#d47b75") (fg-changed "#c3a77a")
        ;; ── surfaces & structure (dark-substrate tokens) ──────
        (bg-main      "#0a0a0a")   ; --bg
        (fg-main      "#ededed")   ; --ink
        (fg-dim       "#9a9a9a")   ; --muted
        (bg-hl-line   "#161616")   ; whisper-quiet current-line wash
        (bg-region    "#2a2a2a")   ; --rule-soft
        (fg-region    unspecified)
        (cursor       "#ededed")
        ;; hairline line numbers, muted active gutter
        (fg-line-number-inactive "#3a3a3a")
        (fg-line-number-active   "#9a9a9a")
        (bg-line-number-inactive "#0a0a0a")
        (bg-line-number-active   "#0a0a0a")
        ;; quiet the mode-line border chrome
        (border-mode-line-active   "#ededed")
        (border-mode-line-inactive "#2a2a2a")
        ;; ── syntax: near-monochrome, accents reserved ─────────
        (comment      "#6a6a6a")   ; --faint, italic
        (docstring    "#6a6a6a")
        (docmarkup    "#9a9a9a")
        (string       "#9a9a9a")   ; --muted, quiet greyscale
        (keyword      "#d4d4d4")
        (builtin      "#d4d4d4")   ; --ink-2
        (fnname       "#ededed")   ; ink
        (type         "#d4d4d4")   ; --ink-2
        (variable     "#ededed")   ; ink
        (constant     "#d4d4d4")
        (preprocessor "#9a9a9a")
        (rx-construct "#d4d4d4")
        (rx-backslash "#d4d4d4")
        ;; Links remain identifiable through underlines.
        (fg-heading-0 fg-main) (fg-heading-1 fg-main)
        (fg-heading-2 fg-main) (fg-heading-3 fg-main)
        (fg-heading-4 fg-dim) (fg-heading-5 fg-dim)
        (fg-heading-6 fg-dim) (fg-heading-7 fg-dim) (fg-heading-8 fg-dim)
        (fg-link      "#d4d4d4")
        (underline-link "#6a6a6a")))

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
