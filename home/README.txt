File Structure

home/
├── samuel-home-configuration.scm       # Full desktop config (minde Wayland session)
├── samuel-wsl2-home-configuration.scm  # WSL2 config (no WM, portable packages)
├── levi-home-configuration.scm         # Levi's config
├── base-home.scm                       # Shared base services/config
├── manifests/                          # guix-shell manifests for agent containers
│   ├── agent-base.scm           # shared base (uv/python/nss-certs)
│   ├── claude.scm
│   ├── codex.scm
│   ├── pi.scm
│   └── deepseek-harness.scm
├── lib/
│   └── identity.scm            # user name / e-mail shared by services (git)
├── packages/
│   ├── base-packages.scm       # All package lists + all-packages() + wsl2-packages()
│   └── ...                     # One-off package definitions (fonts, lem, whisper, etc.)
├── services/                   # Service configurations in Guile Scheme
│   ├── minde.scm                # Wayland session (primary desktop)
│   ├── stumpwm.scm              # X11 session, kept only as a rollback
│   ├── emacs.scm
│   ├── git.scm
│   ├── agent-launchers.scm
│   ├── agent-skills.scm
│   ├── helix.scm / helix-home-services.scm
│   ├── lem.scm
│   ├── redshift.scm
│   ├── fish.scm
│   └── bash.scm
└── files/                      # Dotfiles (shared by all configs)
    └── .config/emacs/          # Emacs config — works on both desktop and WSL2


== Daily Use ==

Desktop (minde Wayland session + full packages):
  guix home reconfigure home/samuel-home-configuration.scm

WSL2 Ubuntu (portable packages, no WM):
  guix home reconfigure home/samuel-wsl2-home-configuration.scm

Validate before reconfiguring:
  make qa-all


== Desktop Session ==

The desktop session is minde (~/Projects/minde), a Wayland window manager
configured via home/services/minde.scm. Personal keybindings, autostart
(wallpaper, eww bar, gammastep, KDE Connect) and terminal selection live
there, layered over minde's own defaults.

StumpWM (home/services/stumpwm.scm) is kept only as an X11 rollback for when
the Wayland session is unusable; it is not the daily driver.

Terminal: foot (Wayland-native) is primary; konsole is the fallback under
both sessions (X11-only commands in stumpwm.scm use konsole directly, since
foot does not run under X11).


== Emacs Daemon ==

Emacs runs as a Shepherd user service (services/emacs.scm, part of
base-services). Open frames with:

  emacsclient -c        # graphical frame
  emacsclient -t        # terminal frame

init.el no longer calls `server-start' — the daemon is the server.
Restart it after config changes with:

  herd restart emacs-daemon


== WSL2 First-Time Setup ==

1. Install Guix on Ubuntu WSL2:
     curl -L https://git.savannah.gnu.org/cgit/guix.git/plain/etc/guix-install.sh \
       | sudo bash

2. Enable Guix daemon (requires systemd, on by default in recent WSL2):
     sudo systemctl enable --now guix-daemon

3. Add Guix bin to PATH (add to ~/.profile for persistence):
     export PATH="$HOME/.config/guix/current/bin:$PATH"

4. Copy channels and pull:
     mkdir -p ~/.config/guix
     cp channels.scm ~/.config/guix/channels.scm
     guix pull

5. Reconfigure home:
     cd ~/System
     guix home reconfigure home/samuel-wsl2-home-configuration.scm

6. Graphical Emacs:
   - Windows 11: WSLg is built-in — run `emacs` and a window appears automatically
   - Windows 10: install VcXsrv, then set DISPLAY=:0.0 before running emacs

Notes:
  - No WM is included — WSL2 has no bare X session to manage.
    Use Windows Terminal as your terminal.
  - All Emacs packages are installed by Guix, identical to the desktop setup.
    No MELPA or package.el bootstrapping needed.

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
