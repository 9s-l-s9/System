Guix Home
=========

The *-home-configuration.scm entry points assemble services from services/
and package groups from packages/base-packages.scm. Static application files
are under files/; manifests/ holds agent
environments and lib/ the shared identity and hook helpers.

From the repository root:
  make qa-all
  make reconfigure-home

For WSL2, use the dedicated entry point with pinned channels and the load path:
  guix time-machine -C channels.scm -- home --load-path=home reconfigure home/samuel-wsl2-home-configuration.scm

See ../README.org for setup and ../QA.md for validation.

== Agent installations ==

Codex settings are seeded from home/services/codex-config.toml by
home/services/codex.scm. The live ~/.codex/config.toml is a writable user
file so Codex can save settings and project trust. Activation migrates old
Guix store symlinks while preserving their contents, and leaves existing
user files intact. Template changes apply only to new installations.

Claude, Codex and Pi use separate npm prefixes under ~/.local/share/agent-tools/.
Their public ~/.local/bin launchers still enter the configured Guix environment;
do not replace those links with a vendor installer. Authentication and sessions
remain in ~/.claude, ~/.claude.json, ~/.codex, and ~/.pi. All three launchers
persist downloads in ~/.cache/agent-npm, including in sandbox mode.

Claude installs the version pinned in scripts/claude-guix.scm only when missing;
its own updater can subsequently update it. Playwright's MCP package is pinned
in scripts/pw-mcp-gen-config.scm. That helper rewrites browser settings only
when changed and registers the server only when its saved command differs.
Pi still checks/installs @latest each launch
and falls back to its installed CLI if an update fails. Codex reuses a legacy
~/.local installation until a private one is installed; its npm update prefix
always points at the private directory so updates preserve the Guix launcher.
Pi requires newer Node than these Guix pins provide: it reuses dsh's checksummed
Node 24 download, but keeps a private interpreter-patched executable in its
own runtime directory.
The shared dsh runtime is not modified. DeepSeek still uses pnpm; its manifest
retains that dependency. Old pnpm installations are not deleted by the launchers.


== Desktop Session ==

The desktop session is minde (~/Projects/minde), a Wayland window manager
configured via home/services/minde.scm. Personal keybindings, autostart
(wallpaper, eww bar, gammastep, KDE Connect) and terminal selection live
there, layered over minde's own defaults.

Terminal: foot (Wayland-native) is primary; konsole is also installed.

Konsole appearance is declared in home/services/konsole.scm: the Gruvbox
profile starts fish directly, uses IBM Plex Mono at 14 pt, 12 px margins,
no extra row spacing, an opaque background and bottom tabs shown only when
needed. Semantic divider lines, command bars/backgrounds and scroll markers
are disabled; shell integration still supports navigation and copying output.
Its initial floating size is 120 columns by 36 rows; minde controls tiled
window sizes.
Guix Home installs konsolerc and the profile/palette as store-backed files.
KConfig's immutable marker keeps application saves from replacing konsolerc;
edit the service and reconfigure instead of saving changes in the GUI.

Fish input, suggestion and completion colors live in home/services/fish.scm.
Colors are set at global scope on each interactive startup, so old universal
theme settings cannot override the declared values. There is no random
Konsole theme switch and no `gh` alias (GitHub CLI owns `gh`).

Starship owns the two-line prompt on desktop and WSL2. Its package and fish
initialization are declared in home/services/starship.scm; edit the adjacent
starship.toml to change the theme. Guix Home installs that file as
~/.config/starship.toml. The Gruvbox segments show the directory, Git branch
and status, and active Guix/language environments. Commands taking at least
two seconds show their duration on the right; failures turn the prompt red.
The existing fonts provide the rounded separators and branch glyph.

Apply with `make reconfigure-home`. Open a fresh Konsole process afterward
to load the new default profile and UI settings. Guix Home backs up existing
unmanaged configuration files when it first takes ownership.


== Emacs Daemon ==

Emacs runs as a Shepherd user service (services/emacs.scm, part of
Samuel's desktop configuration). Open frames with:

  emacsclient -c        # graphical frame
  emacsclient -t        # terminal frame

init.el no longer calls `server-start' — the daemon is the server.
Restart it after config changes with:

  herd restart emacs-daemon


== WSL2 ==

Install Guix on the host and enable its daemon, then clone this repository at
~/Projects/System and use the pinned WSL2 command above. WSLg provides graphical
windows; the WSL2 home configuration does not start a compositor. Its Emacs
packages come from Guix, as on the desktop.

draw.io exports
---------------

The `drawio-render` agent skill bundles the canonical renderer wrapper. The
dotfiles install `~/.local/bin/drawio-render`, with shell aliases for
`drawio-render` and `drawio-export`; that command delegates to the skill script.

Examples:

  drawio-render process-diagram.drawio
  drawio-render -f pdf process-diagram.drawio -o process-diagram.pdf
  drawio-render -f png --scale 2 --transparent --embed-diagram process.drawio
  drawio-render --headless -f svg -d build/diagrams diagrams/*.drawio

The helper uses the official draw.io renderer, but Guix does not currently
provide a `drawio` package in this environment. On Guix, prefer the Docker or
Podman backend from the `drawio-render` skill; it builds a Debian image from the
official draw.io desktop `.deb` and runs the CLI under `xvfb-run`. The helper
also auto-detects a native `drawio` executable first, then Flatpak
`com.jgraph.drawio.desktop`.

Overrides:

  DRAWIO_BIN=/path/to/drawio drawio-render diagram.drawio
  DRAWIO_CONTAINER=1 drawio-render diagram.drawio
  DRAWIO_CONTAINER_ENGINE=podman drawio-render diagram.drawio
  DRAWIO_COMMAND="flatpak run com.jgraph.drawio.desktop" drawio-render diagram.drawio
  DRAWIO_HEADLESS=1 drawio-render diagram.drawio
