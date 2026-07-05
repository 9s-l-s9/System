File Structure

home/
├── samuel-home-configuration.scm       # Full desktop config (StumpWM, X11)
├── samuel-wsl2-home-configuration.scm  # WSL2 config (no WM, portable packages)
├── levi-home-configuration.scm         # Levi's config
├── packages/
│   └── base-packages.scm       # All package lists + all-packages() + wsl2-packages()
├── services/                   # Service configurations in Guile Scheme
│   ├── stumpwm.scm
│   ├── fish.scm
│   ├── helix.scm
│   ├── git.scm
│   └── redshift.scm
└── files/                      # Dotfiles (shared by all configs)
    └── .config/emacs/          # Emacs config — works on both desktop and WSL2


== Daily Use ==

Desktop (StumpWM + full packages):
  guix home reconfigure home/samuel-home-configuration.scm

WSL2 Ubuntu (portable packages, no WM):
  guix home reconfigure home/samuel-wsl2-home-configuration.scm


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
  - StumpWM is NOT included — WSL2 has no bare X session to manage.
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
