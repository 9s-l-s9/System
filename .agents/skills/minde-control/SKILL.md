---
name: minde-control
description: >
  Drive GUI applications on the user's live minde (Wayland compositor)
  session through `mindectl eval`: list and focus windows, click, type,
  paste, scroll, drop files, take screenshots, and verify each step. Use when
  a task needs the real desktop — a logged-in browser window, a GTK file
  dialog, a terminal in another group — and no structured tool (e.g. a
  Playwright browser) can do it. Not for changing minde's configuration or
  keybindings; those live in home/services/minde.scm.
---

# minde control

minde is the user's Wayland compositor (source: `~/Projects/minde`, config:
`home/services/minde.scm`). `mindectl eval '<scheme>'` evaluates an
expression inside the running compositor and prints the result; it works
from the agent sandbox. Everything below acts on the **user's real
screen**: the user may be working at the same time, and a misplaced click
lands in whatever window is under the pointer.

## Safety

- `mindectl eval` runs arbitrary Scheme in the compositor. Queries are fine;
  side effects only as the task needs. Never redefine handlers, reload
  configuration, bind keys or change outputs from here — configuration
  changes go to `home/services/minde.scm` (see AGENTS.md: every binding hangs
  off the `Print` prefix).
- Prefer a structured tool when one fits (Playwright for a web page it can
  reach). Use minde when the task needs the user's own session.
- Before an action that commits something (submit, send, delete, pay,
  accept), stop and confirm unless the task already authorized exactly that.
- Never type into or screenshot password managers, and keep secrets out of
  logs and files. Capture a window region (`wm-screenshot path id`) rather
  than the whole output when other windows may show private content. Write
  screenshots to the scratchpad and delete them when done.
- `kill-current-window!` force-kills the client connection — for a browser
  that is **every** window of it. Close politely (`close-current-window!`)
  or not at all.
- Captchas, logins needing the user's credentials, and 2FA prompts are the
  user's to complete.

## Orientation

```sh
mindectl eval '(map (lambda (i) (list i (window-app-id i) (window-title i))) (all-window-ids))'
mindectl eval '(wm-window-geometry ID)'   ; (x y w h), global logical coords, #f if not visible
mindectl eval '(wm-pointer-position)'     ; (x y)
mindectl eval '(wm-outputs)'
mindectl query state --json               ; groups, frames, focus
mindectl eval '(describe-api)'            ; full live API with signatures
```

Coordinates are zero-based global logical coordinates including bars and
gaps — the same system as `wm-window-geometry`, so compute click targets
relative to the window's (x y), not as guessed absolute pixels.

**Focus:** `(focus-window-by-id! ID)` switches group/frame as needed;
`wm-focus-window`/`wm-raise-window` only act on what is currently shown.
After any dialog, focus often moves (frequently to a terminal): refocus
explicitly and check the window title before the next input.

## Input

| Action | Expression |
| --- | --- |
| Move pointer | `(wm-warp-pointer X Y)` |
| Click | `(wm-click 'left)`, double: `(wm-click 'left 2)`; also `'right`, `'middle` |
| Key | `(wm-send-key MODS "keysym")` — MODS: 0 none, 1 Shift, 4 Ctrl, 8 Alt; add them (5 = Ctrl+Shift) |
| Type | `(wm-type "text" [delay-ms])` — falls back to clipboard for chars the layout can't produce |
| Paste | `(wm-set-clipboard "text")` then `(wm-paste)` (Ctrl+V) |
| Scroll | `(wm-scroll DX DY)` in wheel notches at the pointer |
| Drop files | `(wm-drop-files X Y '("/abs/path.pdf"))` → token |
| Screenshot | `(wm-screenshot "/abs/path.png" [ID])` → token |
| Result of a token | `(wm-automation-status TOKEN)` → `(operation status)` |

Drop statuses: `accepted`, `rejected`, `no-target`, `cancelled`,
`unsupported-target` (XWayland windows don't take drops). Read the
screenshot only after its token reports done. `grim` is a fallback for
full-output captures. To read text from a page: Ctrl+A, Ctrl+C, then
`wl-paste` in the shell (separate calls, give the copy a second).

## Working reliably

- **One input per call, then verify.** Clients render a paste after ~1–2 s:
  wait, screenshot, check. Never repeat a paste because an immediate
  screenshot looked empty — the text ends up twice.
- `wm-type` handles any character (it pastes what the layout can't type);
  for long text, set the clipboard and `wm-paste` instead.
- Escape after typing closes autocomplete dropdowns that would shift the next
  click — but not inside a file dialog's path line, where Escape closes it.
- **Browser address bar:** Ctrl+L, Ctrl+A, paste, Return. After navigation
  the focus stays in the address bar; click into an empty page margin before
  Ctrl+A/C on the page, otherwise you copy the URL.
- **Terminals** (Konsole, foot): paste is Ctrl+Shift+V (`MODS` 5); some TUIs
  treat Ctrl+V as image paste.
- **Drop only onto real dropzones** (dashed border, "drag and drop here").
  Dropped on a page without one, the browser opens the file in the tab and
  the page state is lost. If unsure, use the file dialog.
- **GTK file dialog:** click into the file list first (otherwise Ctrl+L is
  ignored), Ctrl+L, paste the absolute path, Return or click "Open". Refocus
  the previous window afterwards.
- **Confirmation dialogs** (`window.confirm`) change height once a "don't
  allow prompts" checkbox appears: confirm with Return instead of clicking
  fixed coordinates.
- A freshly started browser sometimes renders blank; a new window helps.

When a primitive misbehaves, check `(describe-api)`,
`~/Projects/minde/doc/api.md` and the "Unreleased" section of
`~/Projects/minde/CHANGELOG.md` before working around it.
