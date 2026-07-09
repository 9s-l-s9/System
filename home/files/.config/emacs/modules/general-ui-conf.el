;;; general-ui-conf.el --- General UI improvements -*- lexical-binding: t -*-
;; Author: Samuel Schmidt <samuel@schmidt-contact.com>
;;; Code:

;; No fringe but nice glyphs for truncated and wrapped lines
(fringe-mode '(0 . 0))
;; Note: global-visual-line-mode omitted — conflicts with header-line redisplay

;; General
(setq widget-image-enable nil)

;; Base font size for everything (default face; header-line, minibuffer,
;; etc. all derive from it). 1/10 pt units: 120 = 12 pt. C-x C-+ still
;; scales buffer text on top of this.
(set-face-attribute 'default nil :height 120)

;; Indentation lines
(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)
(setq highlight-indent-guides-method 'character)
(setq highlight-indent-guides-auto-character-face-perc '70)

(global-hl-line-mode +1)

;; Theme — modus-vivendi retinted to the "design skill" dark-substrate
;; register: a fully inverted typeset-document look. Near-monochrome by
;; intent — ink #ededed on #0a0a0a, greyscale for most syntax, with the
;; accents used sparingly (amber leads, lithographic violet supports), as
;; the design tokens prescribe. This is NOT a colourful syntax theme.
;;
;; Palette overrides must be set BEFORE `load-theme'; this is the
;; supported way to retint a Modus theme without forking it.
;; See: https://protesilaos.com/emacs/modus-themes#h:a897b85e-d7d8-43c2-9420-cb615b21fb58
(setq modus-themes-italic-constructs t          ; comments/docstrings in italic — paper feel
      modus-themes-bold-constructs   nil
      modus-themes-common-palette-overrides
      '(;; ── base accent colours, desaturated into the design family ──
        ;; Remapping the named base colours cascades to every semantic
        ;; use Modus derives from them (completions, diffs, errors,
        ;; org headings, rainbow delimiters, prompts…), so the whole
        ;; theme stays in the amber / violet / muted-ink register
        ;; instead of clashing with Modus's vivid defaults.
        (red          "#ee4d42") (red-warmer   "#e85c3a")
        (red-cooler   "#e0566a") (red-faint    "#a37068")
        (red-intense  "#ff5a4f")
        (green        "#7e9b6b") (green-warmer "#8a9b5e")
        (green-cooler "#6f9b84") (green-faint  "#6f7a66")
        (green-intense "#8fb069")
        (yellow       "#c4813e") (yellow-warmer "#cf8a3a")
        (yellow-cooler "#bd8a5e") (yellow-faint "#8c7c5e")
        (yellow-intense "#d89a4a")
        (blue         "#5a8de8") (blue-warmer  "#6f85e0")
        (blue-cooler  "#5a8de8") (blue-faint   "#6f7e9c")
        (blue-intense "#6f9bff")
        (magenta      "#8860b4") (magenta-warmer "#9a6ab0")
        (magenta-cooler "#7a6ab4") (magenta-faint "#7c6e8c")
        (magenta-intense "#a070c4")
        (cyan         "#6f9aa8") (cyan-warmer  "#6f9a9a")
        (cyan-cooler  "#6f8aa8") (cyan-faint   "#6f7c84")
        (cyan-intense "#7ab0bf")
        ;; diff / change backgrounds — subtle dark tints, no neon
        (bg-added     "#11211a") (bg-added-refine   "#1a3328")
        (bg-removed   "#241414") (bg-removed-refine "#3a1c1c")
        (bg-changed   "#221d10") (bg-changed-refine "#332b14")
        (fg-added     "#8fb069") (fg-removed "#ee4d42") (fg-changed "#c4813e")
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
        (keyword      "#c4813e")   ; --accent-amber (the one lead accent)
        (builtin      "#d4d4d4")   ; --ink-2
        (fnname       "#ededed")   ; ink
        (type         "#d4d4d4")   ; --ink-2
        (variable     "#ededed")   ; ink
        (constant     "#8860b4")   ; --accent-violet (support)
        (preprocessor "#9a9a9a")
        (rx-construct "#c4813e")
        (rx-backslash "#8860b4")
        ;; links echo the violet support ink
        (fg-link      "#8860b4")
        (underline-link "#2a2a2a")))

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

;; Relative line numbers
(setq display-line-numbers-current-absolute t
      display-line-numbers-grow-only        t
      display-line-numbers-type             'relative
      display-line-numbers-width            4
      display-line-numbers-width-start      t)
(global-display-line-numbers-mode)

(provide 'general-ui-conf)
;;; general-ui-conf.el ends here
