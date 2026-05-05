(define-module (packages base-packages)
  #:use-module (gnu packages)
  #:export (all-packages)
  #:export (wsl2-packages)
  #:export (programming-packages)
  #:export (emacs-packages)
  #:export (fonts-packages))

;; ── Development ───────────────────────────────────────────────────────────────

(define programming-packages
  (list "python"
        "guile-ts"
        "guile-lsp-server"
        "make"
        ;"r"
        ;"sqlite"
        ;"duckdb"
        ;"gcc-toolchain"
        ))

;; ── CLI utilities (portable — work everywhere) ────────────────────────────────

(define cli-utilities-packages
  (list "tree" "curl"
        "rsync" "zip" "unzip"
        "glibc-locales" "mpv" "ripgrep" "git-lfs" "yt-dlp"))

;; ── System utilities (hardware / desktop daemons) ─────────────────────────────

(define system-utilities-packages
  (list "adb" "wireplumber" "dnsmasq" "hostapd"
        "ark" "flatpak"))

;; ── Fonts (portable — needed for Emacs all-the-icons) ────────────────────────

(define fonts-packages
  (list "font-ipa-ex" "font-fira-code" "font-jetbrains-mono" "font-iosevka"
        "font-google-roboto" "font-lato" "font-inconsolata" "font-victor-mono"
        "font-fantasque-sans"))

;; ── Emacs packages (portable — identical on all machines) ────────────────────

(define emacs-packages
  (list
   "emacs-all-the-icons"
   "emacs-all-the-icons-completion"
   "emacs-all-the-icons-dired"
   "emacs-avy"
   "emacs-cape"
   "emacs-consult"
   "emacs-corfu"
   ;;"emacs-dashboard"
   ;;"emacs-dired-preview"
   "emacs-diredfl"
   ;"emacs-doom-themes"
   "emacs-eat"
   ;"emacs-ebib"
   ;"emacs-ef-themes"
   ;"emacs-elisp-demos"
   "emacs-engrave-faces"
   ;;"emacs-eshell-did-you-mean"
   ;;"emacs-eshell-prompt-extras"
   ;;"emacs-eshell-syntax-highlighting"
   "emacs-flycheck"
   "emacs-focus"
   ;"emacs-gptel"
   "emacs-helpful"
   "emacs-highlight-indent-guides"
   ;"emacs-htmlize"
   "emacs-imenu-list"
   "emacs-magit"
   "emacs-marginalia"
   ;"emacs-markdown-preview-mode"
   "emacs-meow"
   ;; "emacs-nano-modeline"
   "emacs-orderless"
   ;;"emacs-org-modern"
   ;;"emacs-org-present"
   ;;"emacs-org-transclusion"
   ;;"emacs-pdf-tools"
   "emacs-popper"
   "emacs-rg"
   "emacs-sudo-edit"
   ;;"emacs-telega"
   "emacs-undo-tree"
   "emacs-vertico"))

;; ── Editors ───────────────────────────────────────────────────────────────────

(define editors-packages
  (list "emacs-next"
        "helix"))

;; ── Shell ─────────────────────────────────────────────────────────────────────

(define shell-packages
  (list "fish"))

;; ── Terminal emulator (desktop only) ─────────────────────────────────────────

(define terminal-packages
  (list "alacritty"))

;; ── Typesetting ───────────────────────────────────────────────────────────────

(define typesetting-packages
  (list "typst-bin"
        "haunt"))

;; ── X11 / display server ──────────────────────────────────────────────────────

(define xorg-packages
  (list
   ;; "rofi"
   "dunst" "spectacle" "kmix" "xrandr" "arandr"
   "feh" "picom" "redshift"
   "xdg-desktop-portal-wlr" "xsel" "xdg-utils"))

;; ── Wayland (defined but not assembled by default) ───────────────────────────

(define wayland-packages
  (list "gammastep" "mako" "fuzzel"))

;; ── KDE desktop ───────────────────────────────────────────────────────────────

(define kde-packages
  (list "dolphin" "kmix" "konsole"))

;; ── GUI theming ───────────────────────────────────────────────────────────────

(define gui-theming-packages
  (list "breeze-icons" "oxygen-icons" "gtk+"))

;; ── GUI apps (desktop only) ───────────────────────────────────────────────────

(define gui-app-packages
  (list "steam" "inkscape" "gimp"))

;; ── Browser / passwords ───────────────────────────────────────────────────────

(define browser-packages
  (list "zen-browser-bin"
        "bitwarden-desktop"))

;; ── Network ───────────────────────────────────────────────────────────────────

(define network-packages
  (list "openssh"
        "network-manager"
        "network-manager-openvpn"))

;; ── Assemblers ────────────────────────────────────────────────────────────────

;; Full desktop configuration
(define (all-packages)
  (specifications->packages
   (append programming-packages
           cli-utilities-packages
           system-utilities-packages
           xorg-packages
           kde-packages
           gui-theming-packages
           browser-packages
           network-packages
           fonts-packages
           emacs-packages
           editors-packages
           shell-packages
           terminal-packages
           gui-app-packages
           typesetting-packages)))

;; WSL2: portable development environment (no X11, no desktop, no browsers)
(define (wsl2-packages)
  (specifications->packages
   (append programming-packages
           cli-utilities-packages
           fonts-packages
           emacs-packages
           editors-packages
           shell-packages
           typesetting-packages)))
