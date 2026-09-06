# System repo improvement pass, 2026-09-02

Analysis by Claude (Fable 5.1), fixes by Sonnet subagents, reviewed by two
Fable subagents. Nothing is committed; everything below is in the working
tree alongside the owner's own uncommitted edits.

## 1. Changes applied and verified

### Verification performed

| Check | Result |
|---|---|
| `make qa-guile-only` | pass |
| `make qa-system-t450s` (guix time-machine, system build dry-run) | pass, exit 0 |
| `make qa-home-samuel` (home build dry-run) | pass, exit 0; only 4 substitutes to download (nerd-icons x3, font-nerd-symbols), no local builds except minde |
| Full Emacs init loaded in batch against the real profile (`early-init.el` + `init.el`) | loads; dired still enables diredfl + icon mode; eglot knows guile-lsp-server for scheme-mode |
| All five launcher scripts, argv diffed before/after refactor with a fake `guix` on PATH (no args, `--sandbox`, `--help`, `-- --version`, `-m` + project dir) | byte-identical apart from the intended `.sh` -> `.scm` call |
| Launchers invoked through `~/.local/bin`-style symlinks, from other cwds, via `guile -s` | all resolve `scripts/lib/` correctly |
| `guild compile` of every touched `.scm` | pass |
| `sysinfo-daemon` run for 3 s, JSON parsed | `clock` field present and correct |
| `pw-mcp-gen-config.scm` output vs the deleted `.sh` under a fake chromium and temp HOME | byte-identical except HOME-derived paths |
| `foot -e`, `wtype --`, `notify-send -r` accepted by the installed versions | yes (foot 1.27.0, wtype 0.4, libnotify 0.8.3) |
| `/bin/sh` is bash 5.2 (needed by the daemon's `printf %T`) | yes |

### Emacs

- `home/packages/base-packages.scm`
  - removed `emacs-flycheck`, `emacs-popper`, `emacs-engrave-faces` (referenced by no `.el`; eglot uses flymake)
  - replaced `emacs-all-the-icons`, `-completion`, `-dired` with `emacs-nerd-icons`, `-completion`, `-dired`; added `font-nerd-symbols`
  - fonts comment corrected (all-the-icons never needed those families)
- `init.el`: `nerd-icons-completion` use-package. Review found that a
  `marginalia-mode-hook` would never fire because marginalia-conf enables the
  mode earlier; now `:config (nerd-icons-completion-marginalia-setup)`.
- `modules/dired-conf.el`: rewritten; `nerd-icons-dired` and `diredfl` load
  lazily inside `with-eval-after-load 'dired`; dead dired-preview block removed.
- `modules/eglot-conf.el`: no eager `(require 'eglot)`; the scheme server entry
  is added inside `with-eval-after-load`.
- `modules/general-ui-conf.el`: removed the duplicate
  `highlight-indent-guides` hook (init.el already adds it).
- `modules/general-settings.el`: `user-email-address` typo -> `user-mail-address`
  (the old name is not an Emacs variable, so `copyright-names-regexp` formatted nil).
- `git rm home/files/.config/nushell/history.txt` (tracked shell history; nushell not installed).

### Shell, manifests, system

- `home/services/fish.scm`, `bash.scm`: removed
  `LD_LIBRARY_PATH=/usr/lib/cuda-11.2/...` (path does not exist on Guix and a
  global LD_LIBRARY_PATH breaks dynamic linking); removed `*-full` aliases
  (full mode is already the launchers' default); fish agent aliases now use the
  same short `~/.local/bin` launcher names as bash (`~/.local/bin` is on PATH via
  `home-environment-variables-service-type`, which fish sources).
- `home/manifests/codex.scm`: removed duplicate `curl` (in agent-base).
- `systems/base-system.scm`: five stray `use-service-modules` /
  `use-package-modules` lines folded into the `define-module` header
  (`(gnu services cups)` was the only one actually needed).
- `home/services/helix-home-services.scm`: **bug fix**. `toml-value` treated
  `'()` as an inline table, emitting `rulers = {  }`, which Helix rejects with
  "invalid type: map, expected a sequence", so Helix silently ran on default
  config. The table branch now requires `(pair? value)`.

### Desktop

- alacritty removed. `home/packages/base-packages.scm`: `terminal-packages`
  group deleted, `foot` added to `wayland-packages` (konsole stays via
  kde-packages). `home/services/minde.scm`: `MINDE_TERMINAL="foot || konsole"`,
  agent keymap uses `foot -e`. `home/services/stumpwm.scm` (X11 rollback):
  `konsole` / `konsole -e`.
- `scripts/voice-dictate.scm`: works under Wayland. When `WAYLAND_DISPLAY` is
  set it uses `notify-send` (mako), `wl-copy`, `wtype`; otherwise the original
  dunstify/xsel/xdotool path. `wtype` and `libnotify` added to `wayland-packages`.
- eww: `sysinfo-daemon` emits a `clock` field; the bar reads `{stats.clock}`;
  the separate 10 s `date` defpoll is gone.
- `home/README.txt` rewritten for the minde/foot reality (WSL2, Emacs daemon
  and draw.io sections kept; `home/lib/` added after review).

### Launcher scripts

- New `scripts/lib/agent-launch.scm` (module `(agent-launch)`) exporting
  `env`, `require-home`, `mode-name`, `expand-user-path`, `resolve-directory`,
  `maybe-mount`, `maybe-preserve`, `container-socket-mounts`,
  `ensure-directory`, `xdg-runtime-expose`, `preserve-common-env`,
  `git-config-mounts`, `maybe-dry-run`, `run-guix`.
- `claude-guix.scm` 228 -> 162 lines, `codex-guix.scm` 156 -> 102,
  `pi-guix.scm` 172 -> 111, `dsh-guix.scm` 128 -> 106,
  `open-code-guix.scm` 145 -> 88.
- Each script resolves the lib through symlinks with
  `(canonicalize-path (car (command-line)))`.
- New: `AGENT_LAUNCH_DRY_RUN=1 claude-guix ...` prints the guix argv and exits.
- `scripts/pw-mcp-gen-config.sh` and `scripts/chromium-debug.sh` ported to
  Guile (`.scm`) and the `.sh` files deleted; they would otherwise fail the
  Guile-only CI check on first commit. `claude-guix.scm` calls the `.scm`.

## 2. Review finding not fixed (needs a decision)

- `scripts/claude-guix.scm` sandbox mode: the container only shares the
  project dir, `~/.claude`, and the pnpm dirs, so
  `~/Projects/System/scripts/pw-mcp-gen-config.scm`, the chromium extension
  dir, and `~/.cache/pw-mcp-*` are not visible inside. The MCP registration
  block silently no-ops (it ends in `|| true`). Pre-existing design, only the
  file name changed this session. Options: expose `scripts/` +
  `chromium-extensions/` and share `~/.cache/pw-mcp*` in sandbox mode, or run
  the generator on the host before `guix shell`.

## 3. Audit of the rest of the repo (Fable subagent, unfixed)

Line numbers refer to the working tree at the time of the audit. Two claims
were independently confirmed here: the Helix TOML bug (fixed above) and the
dead `/tmp` tmpfs block (item 8).

### Bugs

1. [fixed] Helix config rejected wholesale, see above.
2. [bug] `general-settings.el:84`: the Wayland clipboard hookup is guarded by
   `(eq window-system 'pgtk)`, which is nil while the daemon initialises, so
   `interprogram-cut/paste-function` never get set. Use `(featurep 'pgtk)` or
   `server-after-make-frame-hook`.
3. [bug] `sls-functions.el:16-20`: `sls-reload-init-file` calls
   `server-force-delete` and never restarts the server; after `SPC R` no
   emacsclient can connect. Drop that line.
4. [fixed] `user-email-address` typo.
5. [bug] `focus-conf.el:7-8` hooks `python-mode` but `python-conf.el:17` remaps
   to `python-ts-mode`; focus never activates in Python. Add `python-ts-mode`.
6. [bug] `helix.scm:145` sets formatter `parinfer-rust`, which is not installed
   (upstream has `parinfer-rust` 0.4.3). Every `.scm` save errors once the
   config actually loads (it does now, after the TOML fix). Add to
   `programming-packages`.
7. [bug] `git.scm:21-22` seeds `credential.helper = !gh auth git-credential`
   but `gh` is only in the agent container manifest. Add `"gh"` to
   `cli-utilities-packages` or drop the section (a `/bin/gh` exists on this
   host today, so it works by accident).
8. [bug, confirmed] `base-system.scm:127-133` defines a tmpfs `/tmp`, but
   `T450s.scm` and `X1.scm` build `file-systems` from `%base-file-systems`,
   not from `(operating-system-file-systems base-system)`, so the block is
   dead. Delete it or inherit deliberately (8 GB RAM + tmpfs + guix builds is an
   OOM risk, so deleting is probably right).
9. [bug] `agent-skills.scm:34-38` and `agent-launchers.scm:39-42` `exit 1` when
   `~/Projects/System/...` is missing, and both are in `base-services`, which
   `levi-home-configuration.scm` consumes. Move them to samuel's config. Also
   commit `scripts/dsh-guix.scm`, `home/manifests/deepseek-harness.scm` and
   the agent-launchers edit together.
10. [bug] `scripts/dashboard.scm:96-98`, `terminal-dashboard.scm:136-138,
    210-212` read `wm-T450s.org` / `wm-X1.org` / `wm-palma.org`; only `wm.org`
    and `wm-archive.org` exist. `dashboard.scm` is a subset of
    `terminal-dashboard.scm` and bound nowhere: delete it, fix paths in the other.
11. [bug] Dead or broken scripts: `internet-toggle.scm` requires `(fibers)`
    (not installed) just for a sleep; `lock-screen.scm` execs `i3lock` (not
    installed; the Wayland locker is swaylock); `chromium-debug.scm` execs
    `/bin/chromium`, which only exists inside the FHS container. None are
    invoked by minde.
12. [bug] `scripts/eco-toggle.scm` (bound live at minde prefix `h`): writes
    `intel_pstate/no_turbo=1` (contradicts performance-over-battery), `pkill
    -STOP -f /opt/zen/` matches nothing (zen-browser-bin has no `/opt`),
    unprivileged sysfs write always fails, state file deleted before the
    restore is attempted. Owner decision: keep only backlight + bluetooth.
13. [bug] `gptel-conf.el:22` and `scripts/ask-ai.scm:23` use model id
    `claude-sonnet-4-5`; installed gptel 0.9.9.5 knows `claude-sonnet-4-6` and
    the dated 4-5 id. The API accepts the alias but gptel warns and lacks
    capability metadata.
14. [bug, in-progress owner edits] `modeline-conf.el:150-160`
    `sls--minibuffer-pad` bakes `(face-background 'default)` at load time,
    which is `"unspecified-bg"` on the daemon's TTY frame (the same problem
    `sls--default-color` fixes elsewhere). Reuse it and re-run on
    `server-after-make-frame-hook`. Lines 118-120 register both
    `after-make-frame-functions` and `server-after-make-frame-hook`; the latter
    is redundant.

### Speed-ups

15. [safe-fix] Emacs daemon startup: eager `require`s. `dap-conf.el:4,16`
    pulls dap-mode, lsp-mode, lsp-docker, posframe, treemacs, hydra at every
    start; also `gptel-conf.el:4`, `helpful-conf.el:2`, `focus-conf.el:2`,
    `cape-conf.el:2`, `imenu-list-conf.el:2`, `eca-conf.el:19`. Convert to
    `use-package :commands` / `with-eval-after-load`. Only meow, corfu,
    vertico, marginalia, orderless and the theme need eager loading.
16. [safe-fix] `channels.scm`: the audit found no package referenced from
    `rde`, `radix`, `rosenthal`, `guix-science`; `saayix` only duplicates
    `zen-browser-bin` (also in `binary-guix`, so the spec is ambiguous);
    `pantherx` is kept solely for `d2`. Each extra channel slows `guix pull`
    and time-machine. Verify with `guix show PKG` (it prints the channel) before
    dropping. `binary-guix` has no `introduction`.
17. [decision] `%desktop-services` extras at boot: geoclue, modem-manager,
    colord, accountsservice, sane, cups-pk-helper are unused under SDDM+minde.
    CUPS `web-interface? #t` + hplip + epson drivers bloat every reconfigure.
18. [decision] TLP `cpu-scaling-governor-on-bat "powersave"` contradicts the
    stated preference; set both governors to `"performance"`.

### Dead code and duplicates

19. [safe-fix] Dead Emacs modules: `pdf-tools-conf.el` (not required, package
    commented out, calls `pdf-tools-install` twice), `valsi-conf.el` (not
    required; naur-conf disables valsi), `imenu-list-conf.el` (settings
    duplicated in `window-conf.el:50-51`). `orderless-conf.el:8-14`
    `orderless-fast` unused. `init.el` comment "no-op until emacs-eca is
    installed" is stale.
20. [safe-fix] 25 `global-set-key` calls in feature modules (`dap-conf.el:60-71`,
    `gptel-conf.el:100-106`, `helpful-conf.el:4-9`, `window-conf.el:56-57`)
    violate AGENTS.md; `C-c a` / `C-c A` duplicate leader `a` / `A`. Move to
    `keybindings-conf.el`.
21. [decision] `keybindings-conf.el`: `Q` and `X` both `meow-goto-line`; `c`
    (`copy-region-as-kill`) duplicates `y` (`meow-save`); `meow-append` unbound
    (`a` is avy); `j`/`k` are prev/next. Leader `c` collides with the commented
    minuet `c`.
22. [safe-fix] Unused custom packages in `home/packages/`: `gptel-master.scm`
    (upstream emacs-gptel used), `lem-package.scm` (upstream lem 2.3.0 used),
    `schemesh.scm` (0.7.6 vs upstream 0.9.3), `font-inter.scm` (upstream 4.1),
    `emacs-typst-ts-mode.scm` (placeholder hash, unbuildable),
    `emacs-ada-light-mode.scm` (`commit "main"`), `mindre-theme.scm` (template).
    `minuet.scm` only if minuet stays disabled. `modus-buffer-theme.scm` loads
    `/home/samuel/Projects/emacs-buffer-theme/guix.scm`, which breaks
    `all-packages` for levi/WSL.
23. [safe-fix] Manifest duplication: `node@22` in all four agent manifests,
    `pnpm@9` in three, `ripgrep`/`fd` in pi + deepseek: fold into
    `agent-base.scm`. `.agents/skills/guix-packaging/manifest.scm` is entirely
    covered by agent-base; `document-intelligence/manifest.scm` mostly.
24. [safe-fix] Helix service: the `[[grammar]]` override only affects
    `hx --grammar fetch`; `package` equals the default; `extra-config` unused.
25. [safe-fix] Misc: `git` in both system and home packages;
    `xf86-input-libinput/wacom` in system packages do nothing under Wayland;
    minde installed both system-wide and via `minde.scm`; `redshift.scm` dead;
    `lem.scm` imports all of `(gnu)`; `lp` group comment wrong; zram comment
    contradicts T450s swap; T450s-only tuning (`i915.enable_psr=0`, thermald,
    zram 4G) lives in base and leaks to X1; X1 lacks the `de`/`bone` console
    layout; elogind lid=ignore vs the memory note saying lid suspends.
26. [safe-fix] Hygiene: `.gitignore` covers only `.codex`;
    `assets/archive.tar.gz` (1.3 MB of old awesome/rofi/nushell dotfiles)
    referenced nowhere; `scripts/Readme.org` is old StumpWM Lisp;
    `samsung-monitor.scm` / `setup-devices.scm` X11-only and uninvoked;
    `minde-console-continue.scm` + `.log` + `.png` are one-shot junk;
    `check-guile-only.scm` only checks tracked files; `ARCHITECTURE.md` still
    StumpWM-centred and lists `dashboard.scm` as bound; root notes
    (`BUFFER-THEME-PACKAGE-PROJECT.md`, `emacs-ai-improvements.txt`,
    `sddm-numlock-dead-keyboard.md`) belong in `docs/`; `minde-package.scm` is
    load-bearing and undocumented; untracked `pw-stealth/` is 25 MB of
    node_modules.
27. [decision] `whisper-conf.el:31` hardcodes the T450s mic device (`"default"`
    works on both hosts). `cape-conf.el:15-20` adds `cape-tex` /
    `cape-elisp-*` to every prog/text/conf buffer; scope them.
    `gptel-conf.el:34` registers tools only after `gptel-transient` loads;
    `gptel-make-tool` lives in `gptel.el`, register unconditionally.

### Flagged earlier in the session (owner preference)

- `plasma-desktop-service-type` is the largest closure and service set in the
  system config while the session is minde.
- `emacs-next-pgtk` (Emacs 31 snapshot) vs `emacs-pgtk` 30.2 release.
- Ten font families installed; only iA Writer Mono S, IBM Plex and Space Mono
  are referenced.
- `home/services/stumpwm.scm` and `redshift.scm` unused by any home config.

## 4. Second fix round (same day, Sonnet subagents)

All section 3 items were applied except the ones listed under "left alone".
Verification after the combined changes: `make qa-guile-only`,
`make qa-system-t450s`, `make qa-system-x1`, `make qa-home-samuel`,
`make qa-home-levi` all exit 0 (time-machine dry-runs); every agent manifest
evaluates via `guix time-machine -C channels.scm -- shell -m FILE --dry-run`;
full Emacs init loads in batch and the lazily-loaded dap/gptel/cape bodies
execute without error.

Emacs (items 2, 3, 5, 13, 14, 15, 19, 20, 27):
- pgtk clipboard guard now `(featurep 'pgtk)`; `sls-reload-init-file` no longer
  deletes the server; focus-mode hooks python-ts-mode; gptel model
  `claude-sonnet-4-6`; modeline minibuffer padding uses `sls--default-color`
  and refreshes on `server-after-make-frame-hook`; dap/gptel/helpful/focus/
  cape/eca now load lazily; pdf-tools-conf, valsi-conf, imenu-list-conf and
  `orderless-fast` deleted; all global-set-key calls moved to
  keybindings-conf.el (gptel `C-c a/A` dropped, leader a/A already exist);
  whisper mic is "default"; cape-elisp-* scoped to elisp modes, cape-tex to
  text/org; gptel tools register on gptel load.

Scripts (items 10, 11, 12, 13, 26):
- deleted dashboard.scm, Readme.org, samsung-monitor.scm, setup-devices.scm;
  terminal-dashboard reads wm.org / wm-archive.org; internet-toggle no longer
  needs fibers; chromium-debug finds chromium on PATH; eco-toggle reduced to
  backlight + bluetooth with the restore-order bug fixed; ask-ai model
  `claude-sonnet-4-6`; check-guile-only also scans untracked files;
  .gitignore covers pw-stealth/, the minde-console-continue artefacts, *.elc, *.go.

System and services (items 8, 9, 10, 16, 18, 25):
- dead tmpfs /tmp block removed; agent-skills/agent-launchers moved from
  base-services into samuel's config (levi no longer depends on the repo
  checkout); stumpwm `dashboard` command removed; channels.scm dropped rde,
  radix, rosenthal, guix-science, saayix after `guix show` traced every used
  package to guix/nonguix/binary-guix/pantherx (d2); TLP governor on battery
  is "performance"; lp comment fixed; T450s kernel arguments moved to
  T450s.scm; X1 gets the de/bone layout; lem.scm imports narrowed;
  redshift.scm deleted.

Packages, manifests, hygiene (items 6, 7, 22, 23, 24, 26):
- parinfer-rust added; `gh` is not a Guix spec, the package is `github-cli`
  (fixed in base-packages and in agent-base.scm, where the same typo was
  pre-existing); eight unused custom package files deleted (gptel-master,
  lem-package, schemesh, font-inter, emacs-typst-ts-mode, emacs-ada-light-mode,
  mindre-theme, minuet); modus-buffer-theme.scm guarded so a missing
  ~/Projects/emacs-buffer-theme checkout no longer breaks all-packages;
  node@22, pnpm@9, ripgrep, fd moved into agent-base.scm and the two skill
  manifests now layer on agent-base; helix.scm lost the inert grammar override
  and default package field; assets/archive.tar.gz removed; the three root
  notes moved to docs/; minde-package.scm has a header; ARCHITECTURE.md updated.

Left alone on purpose (owner preference): plasma-desktop-service-type, CUPS
web interface and drivers, %desktop-services extras (item 17),
emacs-next-pgtk, the font list, the Meow j/k and Q/X bindings (item 21),
minde installed both system-wide and in home, git in both system and home,
elogind lid handling, the claude-guix sandbox-mode MCP config path (section 2).

## 5. Next steps

Reconfigure to pick up the package changes:

```
guix home reconfigure ~/Projects/System/home/samuel-home-configuration.scm
herd restart emacs-daemon
```

Then, if wanted, a second fix round on items 2, 3, 5, 6, 7, 8, 15, 19, 20, 22,
23 (all mechanical) with the decisions on 12, 16, 17, 18, 21 made first.
