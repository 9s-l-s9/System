# `modus-buffer-themes`: concurrent Modus themes for Emacs buffers

## Objective

Build an Emacs package that applies different Modus-family content themes to
simultaneously visible buffers without changing the globally enabled theme.

The intended configuration is:

```elisp
(setq modus-buffer-theme-rules
      '(((org-mode markdown-mode gfm-mode) . modus-operandi)
        ((term-mode eat-mode vterm-mode eshell-mode) . modus-vivendi)))

(modus-buffer-themes-global-mode 1)
```

This should permit a light Org or Markdown buffer beside a dark terminal while
the mode line, minibuffer, frame decorations, and other shared UI retain the
global theme.

The package is deliberately not a generic per-buffer Custom-theme engine.

## Compatibility contract

A theme is supported when it:

1. belongs to the `modus-themes` family;
2. is returned by `modus-themes-get-themes`;
3. exposes the semantic palette roles required by the package through
   `modus-themes-get-color-value`.

The package should validate this contract rather than maintain a hard-coded
theme list:

```elisp
(defconst modus-buffer-themes-required-colors
  '(bg-main fg-main fg-dim
    keyword string comment
    builtin fnname variable constant
    bg-region))

(defun modus-buffer-theme-supported-p (theme)
  (and (memq theme (modus-themes-get-themes))
       (seq-every-p
        (lambda (role)
          (stringp (modus-themes-get-color-value role nil theme)))
        modus-buffer-themes-required-colors)))
```

This naturally supports the official variants currently reported by Modus:

```text
modus-operandi
modus-operandi-tinted
modus-operandi-deuteranopia
modus-operandi-tritanopia
modus-vivendi
modus-vivendi-tinted
modus-vivendi-deuteranopia
modus-vivendi-tritanopia
```

A third-party theme can be supported if it genuinely implements the same Modus
family and semantic-palette interface.

## Honest feature boundary

The package applies a Modus content theme to a buffer. It does not create a
fully independent Emacs UI theme for every buffer.

### Locally themed

- `default`, `fixed-pitch`, and `variable-pitch`
- font-lock syntax faces
- links, buttons, warnings, errors, and success states
- region, highlight, search, match, and lazy-highlight faces
- line numbers, whitespace, trailing whitespace, and indentation guides
- Org content faces
- Markdown content faces
- Dired and compilation content faces
- terminal text and ANSI palettes
- optional selected-window content accent

### Left under the global theme

- mode line and header line
- minibuffer and completion child frames
- tab bar and tool bar
- window dividers, fringes, and scroll bars
- frame borders and decorations
- tooltips and unrelated popup frames

This boundary avoids repainting shared UI whenever focus changes and keeps the
behavior predictable.

## Why this is possible

Normal theme activation is global:

```elisp
(load-theme 'modus-operandi t)
```

`load-theme`, `enable-theme`, and `custom-enable-theme` install faces in the
global face table and have no buffer argument.

Emacs separately supports buffer-local face replacement through
`face-remapping-alist`. The package can construct local faces from the selected
Modus palette and install them with `face-remap-add-relative`:

```elisp
(face-remap-add-relative
 'font-lock-keyword-face
 `(:foreground ,(modus-themes-get-color-value
                  'keyword nil 'modus-operandi)))
```

The returned remapping cookie must be retained so the package can remove only
its own entry later. Replacing `face-remapping-alist` wholesale would destroy
text scaling and remappings owned by other packages.

## Why the Modus restriction matters

Unrelated Custom themes do not share semantic color names, face coverage, or
configuration conventions. They may also execute arbitrary Lisp and set global
variables that cannot be localized safely.

Modus provides a shared semantic vocabulary:

```elisp
(modus-themes-get-color-value 'bg-main nil 'modus-operandi)
;; => "#ffffff"

(modus-themes-get-color-value 'fg-main nil 'modus-operandi)
;; => "#000000"

(modus-themes-get-color-value 'keyword nil 'modus-vivendi)
;; => "#b6a0ff"
```

The package can therefore translate stable roles into a curated collection of
buffer-local faces instead of attempting to interpret arbitrary theme code.

## Package architecture

### 1. Palette provider

Validate a theme and return a cached role-to-color map:

```elisp
modus-operandi =>
  ((bg-main . "#ffffff")
   (fg-main . "#000000")
   (keyword . "#531ab6")
   ...)
```

The default behavior should use the theme's standard palette:

```elisp
(modus-themes-get-color-value role nil theme)
```

An option can permit current user palette overrides:

```elisp
(modus-themes-get-color-value role t theme)
```

This choice must be explicit because a common override can intentionally make
both Operandi and Vivendi use similar backgrounds.

### 2. Semantic face map

Maintain a curated mapping from Emacs faces to Modus roles:

```elisp
'((default                  :background bg-main :foreground fg-main)
  (shadow                   :foreground fg-dim)
  (font-lock-keyword-face   :foreground keyword)
  (font-lock-string-face    :foreground string)
  (font-lock-comment-face   :foreground comment)
  (font-lock-builtin-face   :foreground builtin)
  (font-lock-function-name-face :foreground fnname)
  (font-lock-variable-name-face :foreground variable)
  (font-lock-constant-face  :foreground constant)
  (region                   :background bg-region))
```

Expand role symbols to concrete colors before passing the attribute plist to
the face-remapping API.

Keep this map in the core package because these faces are stable and broadly
applicable.

### 3. Mode adapters

Optional adapters extend the core map:

```text
modus-buffer-themes-org.el
modus-buffer-themes-markdown.el
modus-buffer-themes-terminal.el
modus-buffer-themes-dired.el
modus-buffer-themes-compile.el
```

Adapters should be loaded only after their owning package and should declare
which faces and variables they manage. This prevents the core package from
depending on Org, Markdown Mode, Eat, or Vterm.

The first release can keep adapters in one source file if that is simpler, but
their internal boundaries should remain explicit.

### 4. Buffer-local state

Suggested state:

```elisp
(defvar-local modus-buffer-theme nil)
(defvar-local modus-buffer-theme--face-cookies nil)
(defvar-local modus-buffer-theme--saved-variables nil)
```

Applying a theme should be transactional:

1. Validate and resolve the complete palette and face map.
2. Save any local variables required by the active adapter.
3. Install face remappings, collecting every cookie.
4. Apply adapter-specific buffer-local variables.
5. Set `modus-buffer-theme` only after all operations succeed.
6. On error, remove new cookies and restore saved values.

Clearing must remove only package-owned state and reveal the global theme
without recreating or guessing its values.

### 5. Rule engine

Keep automatic mode policy separate from manual theme assignment:

```elisp
(defcustom modus-buffer-theme-rules nil
  "Alist mapping lists of major modes to Modus themes.")
```

Rules should match using `derived-mode-p`:

```elisp
(((org-mode markdown-mode gfm-mode) . modus-operandi)
 ((term-mode eat-mode vterm-mode eshell-mode) . modus-vivendi))
```

File-extension matching may be offered as an explicit fallback but should not
be the primary classifier.

`modus-buffer-themes-global-mode` can apply the rule engine through
`after-change-major-mode-hook`. Manual `modus-buffer-theme-set` must remain
usable without enabling the global mode.

## Public API

Minimum version-1 API:

```elisp
;; Test whether THEME satisfies the compatibility contract.
(modus-buffer-theme-supported-p THEME)

;; Apply THEME's content palette to the current buffer.
(modus-buffer-theme-set THEME)

;; Remove the package's local faces and variables from the current buffer.
(modus-buffer-theme-clear)

;; Rebuild the current buffer from its assigned theme.
(modus-buffer-theme-refresh)

;; Rebuild every buffer currently assigned THEME.
(modus-buffer-theme-refresh-theme THEME)

;; Enable or disable automatic rule-based assignment.
(modus-buffer-themes-global-mode 1)
```

Interactive theme selection should offer only values returned by
`modus-themes-get-themes` that pass `modus-buffer-theme-supported-p`.

## Terminal adapter

Terminal colors are not controlled solely by ordinary faces. Depending on the
terminal implementation, the adapter may need buffer-local values for:

```elisp
ansi-color-names-vector
ansi-term-color-vector
xterm-color-names
xterm-color-names-bright
```

Eat and Vterm may use their own palette faces, variables, or native-module
state. Each adapter must verify whether its consumer reads values dynamically
or caches them during initialization. Cached palettes may require an explicit
refresh or redraw.

The terminal adapter should derive the ANSI palette from Modus semantic roles,
not copy literal colors from one theme.

## Window-local selected-buffer accent

Emacs 31 supports a filtered expression inside `face-remapping-alist`:

```elisp
(:filtered (:window PARAMETER VALUE) FACE-SPECIFICATION)
```

This permits two windows showing the same buffer to render a face differently.
An optional focus mode can add a small contrast shift to the assigned buffer
theme:

```elisp
(face-remap-add-relative
 'default
 `(:filtered (:window modus-buffer-theme-active t)
             (:background ,active-background)))
```

Selection hooks clear the parameter from all windows and set it on the selected
window. The active background must be derived independently from each buffer's
assigned `bg-main`, so light and dark buffers both shift in the correct
direction.

This feature should be optional and guarded by an Emacs-version or capability
check. It is not required for basic buffer-local themes.

## Lifecycle concerns

### Major-mode changes

Changing major mode calls `kill-all-local-variables`, which removes the local
theme state. The global rule mode should reassign the appropriate theme from
`after-change-major-mode-hook`.

### Faces defined after assignment

A mode package may define faces after the local theme was applied. Its adapter
should run after that package loads and refresh buffers using the corresponding
mode. Avoid refreshing every themed buffer after every library load.

### Global theme changes

A local Modus theme uses concrete colors and should remain stable when the
global theme changes. The package should provide an option controlling whether
buffers are automatically refreshed after `load-theme`.

Automatic advice should be part of the optional global integration mode, not an
unavoidable side effect of loading the library.

### User palette overrides

Changing Modus palette overrides does not automatically update existing local
remappings. `modus-buffer-theme-refresh-theme` should invalidate the relevant
cache and rebuild affected buffers.

## Rejected approaches

### Switching the global theme with buffer focus

Every frame and window repaints, focus changes can flash, and light and dark
buffers cannot remain visible simultaneously.

### Frame-local face attributes

Frame-local faces can distinguish separate OS-level frames but cannot
distinguish split windows or assign themes by buffer.

### Whole-buffer overlays

An overlay can be restricted to a window, but its background covers buffer
glyphs rather than the entire unused window surface. Overlay precedence also
interferes with syntax and selection faces.

### Indirect buffers per window

Indirect buffers support independent local variables but change buffer
identity, names, hooks, process associations, and mode state. Some modes forbid
cloning through `no-clone-indirect`.

### Replaying every Custom theme setting

This gives higher apparent fidelity but depends on internal theme
representations, includes faces for unrelated packages, and still cannot safely
localize arbitrary `theme-value` settings. It may remain an experimental Modus
backend, but it is not the version-1 design.

## Project layout

```text
modus-buffer-themes/
├── modus-buffer-themes.el
├── README.md
├── CHANGELOG.md
├── LICENSE
├── test/
│   ├── modus-buffer-themes-test.el
│   └── modus-buffer-themes-render-test.el
└── examples/
    └── light-prose-dark-terminal.el
```

The package should depend only on Emacs, Modus Themes, and built-in libraries
such as `face-remap`, `color`, `seq`, and `cl-lib`. Mode adapters must not make
their corresponding external modes mandatory dependencies.

## Test strategy

Core tests should run without the user's configuration:

```sh
emacs --batch --quick -L . -l test/modus-buffer-themes-test.el
```

Required ERT coverage:

1. Accept all compatible themes reported by `modus-themes-get-themes`.
2. Reject a non-Modus theme with a clear user error.
3. Resolve required semantic colors for both Operandi and Vivendi.
4. Apply Operandi to one buffer and Vivendi to another simultaneously.
5. Confirm their local `default`, font-lock, region, and line-number faces use
   different resolved colors.
6. Confirm `custom-enabled-themes` never changes during local assignment.
7. Preserve unrelated face remappings such as text scaling.
8. Clear a theme without leaving cookies or local variables behind.
9. Apply, refresh, and clear repeatedly without growing
   `face-remapping-alist`.
10. Recover transactionally from an invalid face specification.
11. Reassign correctly after a major-mode change.
12. Verify Org and Markdown adapter faces.
13. Verify ANSI palette derivation and restoration for each terminal adapter.
14. On Emacs 31, verify the same buffer in two windows receives the optional
    selected-window accent only in the selected window.

Graphical integration tests should create temporary frames and export them with
`x-export-frames` when Cairo PNG support is available. Pixel comparisons should
prove that an Operandi prose buffer and Vivendi terminal buffer are visibly
different while shared frame UI is unchanged.

## Milestones

### Milestone 1: core Modus palettes

- Implement compatibility validation and palette caching.
- Implement the curated core face map.
- Implement transactional set, clear, and refresh.
- Prove two buffers can retain opposite Modus palettes simultaneously.

### Milestone 2: prose and terminal adapters

- Add Org and Markdown face maps.
- Add ANSI palette derivation.
- Add adapters for Term, Eshell, Eat, and Vterm.
- Verify restoration of adapter-owned local variables.

### Milestone 3: rules and lifecycle

- Add mode-to-theme rules and the global assignment mode.
- Handle major-mode changes and late-loaded adapter faces.
- Add configurable reaction to global theme and palette changes.

### Milestone 4: window focus and release

- Add the optional Emacs 31 window-filtered focus accent.
- Add graphical render tests.
- Add package headers, byte compilation, linting, documentation, and release
  metadata.

## Definition of done

Version 1 is complete when:

1. A simultaneously visible Org or Markdown buffer uses Modus Operandi content
   colors while a terminal buffer uses Modus Vivendi content colors.
2. The globally enabled theme and all shared UI remain unchanged as focus moves.
3. Core, prose, region, search, line-number, and terminal ANSI colors derive
   from the assigned Modus palette.
4. Clearing a local theme restores every prior remapping and local variable
   without residue.
5. Repeated mode changes, refreshes, assignments, and clears do not leak state.
6. The behavior passes clean `emacs --quick` ERT tests and a graphical render
   comparison.
