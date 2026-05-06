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
