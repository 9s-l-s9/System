# Agent guidance for this repo

Conventions an agent must follow when changing this configuration.

## Configuration is one dedicated file per application

Settings live in a file scoped to the application they configure — not scattered
into unrelated files. Before adding any setting, **find and read the file that
already owns that concern**, then edit there.

## Keybindings: always read where they are defined first

Do **not** add ad-hoc keybindings (e.g. `global-set-key`) into feature modules.
Find the dedicated keybinding location for that application and add it there,
matching the existing style and checking for conflicts.

- **Emacs** — keybindings live in
  `home/files/.config/emacs/modules/keybindings-conf.el`. This uses **Meow**
  modal editing: the leader map (prefix shown there) is canonical, e.g.
  `'("a" . gptel)`. A feature module (`gptel-conf.el`, etc.) should configure
  the feature; its keys go in `keybindings-conf.el`.
- **StumpWM** — keybindings live in `home/services/stumpwm.scm` under the
  `keymaps` section. Prefix key is `Print`; commands are `defcommand`s that
  `run-shell-command` into `scripts/*.scm`, bound in the root keymap (or a
  prefix sub-map).
- **minde** — keybindings live in `home/services/minde.scm` (`personal-init`,
  via `bind-prefix-key!`). **Hard rule: every binding hangs off the `Print`
  prefix key — never bind Super, Ctrl, Alt, or any other modifier chord.**
  Prefix key + plain key (or Shift-key, or a sub-keymap) only. Always pass a
  doc string so the `?` which-key menu stays complete.

## Scripts are Guile-only

Everything in `scripts/` must be `.scm` (or `.org`), enforced by
`scripts/check-guile-only.scm`. No bash/python scripts.
