(define-module (packages base-packages)
  #:use-module (gnu packages)
  #:use-module (packages anki)
  #:use-module (packages eca)
  #:use-module (packages font-ia-writer)
  #:use-module (packages font-space-mono)
  #:use-module (packages modus-buffer-theme)
  #:use-module (packages whisper)
  #:use-module (packages zen)
  #:export (all-packages)
  #:export (wsl2-packages)
  #:export (programming-packages)
  #:export (utilities-packages)
  #:export (emacs-packages)
  #:export (fonts-packages)
  #:export (xorg-packages))

;; Development

(define programming-packages
  (list "python"
        "guile-ts"
        "guile-lsp-server"
        "make"
        "python-lsp-server"    ; pylsp LSP backend for eglot
        "python-debugpy"       ; DAP debug adapter
        "ruff"                 ; fast linter + formatter
        "python-pytest"        ; test runner
        "python-mypy"          ; static type checker
        "tree-sitter-python"   ; grammar for python-ts-mode
        "openjdk"              ; ECA server runtime (JVM)
        "parinfer-rust"        ; helix.scm formatter for scheme files
        ;"r"
        ;"sqlite"
        ;"duckdb"
        ;"gcc-toolchain"
        ))

;; CLI utilities (portable: work everywhere)

(define cli-utilities-packages
  (list "tree" "curl"
        "rsync" "zip" "unzip"
        "glibc-locales" "mpv" "ripgrep" "git-lfs" "yt-dlp" "d2"
        "guile-json"                 ; scripts/ask-ai.scm
        "whisper-cpp" "ffmpeg"       ; local speech-to-text (whisper.el)
        "github-cli"))               ; `gh`, used as services/git.scm's credential helper

;; System utilities (hardware / desktop daemons)

(define system-utilities-packages
  (list "adb" "hostapd"     ; wireplumber comes from home-pipewire-service-type
        "alsa-utils"        ; alsamixer/amixer for the hardware (card-level)
                            ; HDA controls PipeWire doesn't manage (Speaker,
                            ; PCM, Headphone); use `alsamixer -c 0`
                            ; dnsmasq intentionally omitted: NetworkManager manages
                            ; its own internal dnsmasq instance for split DNS; a
                            ; second dnsmasq binary in PATH causes version conflicts
                            ; and DNS failures after channel updates.
        "ark" "flatpak"))

(define utilities-packages
  (append cli-utilities-packages
          system-utilities-packages))

;; Fonts (portable). font-nerd-symbols supplies the glyphs for Emacs nerd-icons.

(define fonts-packages
  (list "font-ipa-ex" "font-fira-code" "font-jetbrains-mono" "font-iosevka"
        "font-google-roboto" "font-lato" "font-inconsolata" "font-victor-mono"
        "font-fantasque-sans"
        "font-nerd-symbols"           ; icon glyphs for emacs-nerd-icons
        ;; design-skill manual aesthetic: Plex Mono body; Space Mono is custom.
        "font-ibm-plex"))

;; Emacs packages (portable: identical on all machines)

(define emacs-packages
  (list
   "emacs-avy"
   "emacs-cape"
   "emacs-consult"
   "emacs-corfu"
   ;;"emacs-dashboard"
   ;;"emacs-dired-preview"
   "emacs-dap-mode"
   "emacs-diredfl"
   ;"emacs-doom-themes"
   "emacs-eat"
   ;"emacs-ebib"
   ;"emacs-ef-themes"
   ;"emacs-elisp-demos"
   ;;"emacs-eshell-did-you-mean"
   ;;"emacs-eshell-prompt-extras"
   ;;"emacs-eshell-syntax-highlighting"
   "emacs-focus"
   "emacs-gptel"
   "emacs-helpful"
   "emacs-highlight-indent-guides"
   ;"emacs-htmlize"
   "emacs-imenu-list"
   "emacs-magit"
   "emacs-marginalia"
   ;"emacs-markdown-preview-mode"
   "emacs-meow"
   "emacs-nerd-icons"
   "emacs-nerd-icons-completion"
   "emacs-nerd-icons-dired"
   ;; "emacs-minuet"       ; AI inline completion; disabled until an API key exists

   ;; "emacs-nano-modeline"
   "emacs-orderless"
   ;;"emacs-org-modern"
   ;;"emacs-org-present"
   ;;"emacs-org-transclusion"
   ;;"emacs-pdf-tools"
   "emacs-rg"
   "emacs-sudo-edit"
   ;;"emacs-telega"
   "emacs-vertico"
   "emacs-vundo"))

;; Custom packages missing from upstream Guix (package objects, not specs).
;; emacs-modus-buffer-theme is #f on machines without the owner's personal
;; /home/samuel/Projects/emacs-buffer-theme checkout (see packages/modus-buffer-theme.scm);
;; filter it out rather than including a #f in the package list.
(define custom-home-packages
  (filter identity
          (list anki-bin
                emacs-eca
                emacs-modus-buffer-theme
                emacs-whisper
                font-ia-writer
                font-space-mono)))

;; Editors

(define editors-packages
  (list "emacs-next-pgtk"
        "helix"))

;; Shell

(define shell-packages
  (list "fish"))

;; Typesetting

(define typesetting-packages
  (list "typst-bin"
        "haunt"))

;; X11 applications retained for an easy StumpWM rollback, but deliberately
;; not included by `all-packages'.

(define xorg-packages
  (list
   ;; "rofi"
   "dunst" "xrandr" "arandr"
   "feh" "picom" "redshift" "xset"
   "xdotool"                          ; type transcription into focused window
   "numlockx"                         ; clear SDDM's forced NumLock at session start
   "xsel"))

;; Wayland (defined but not assembled by default)

(define wayland-packages
  (list "gammastep" "mako" "fuzzel" "swaybg" "wl-clipboard"
        "foot"                        ; terminal (konsole from kde-packages is the fallback)
        "wtype" "libnotify"           ; scripts/voice-dictate.scm on Wayland: typing + notify-send
        "grim" "slurp"                ; Wayland screenshots (grim + region select)
        "eww"                         ; Minde bar and sysinfo widgets
        "brightnessctl"
        "xdg-desktop-portal-wlr"
        "xdg-utils"))

;; KDE desktop

(define kde-packages
  (list "dolphin" "kmix" "konsole"
        ;; Phone<->PC file transfer (also works without a Plasma session):
        ;; provides the kdeconnectd daemon, `kdeconnect-cli`, and the
        ;; `kdeconnect-indicator` tray app. Uses ports 1714-1764 TCP/UDP,
        ;; which are already reachable (no firewall service on this system).
        "kdeconnect"
        ;; Dolphin KIO workers for remote/device protocols. Without this the
        ;; mtp:// worker is missing and browsing a USB-connected phone errors
        ;; out. Pulls in libmtp for the actual MTP transport.
        "kio-extras"))

;; GUI theming

(define gui-theming-packages
  (list "breeze-icons" "oxygen-icons" "gtk+"))

;; GUI apps (desktop only)

(define gui-app-packages
  (list "steam" "inkscape" "gimp"))

;; Browser / passwords

(define browser-packages
  (list "bitwarden-desktop"))

;; Network

(define network-packages
  (list "openssh"
        "network-manager"
        "network-manager-openvpn"))

;; Assemblers

;; Full desktop configuration
(define (all-packages)
  (append
   (specifications->packages
    (append programming-packages
            cli-utilities-packages
            system-utilities-packages
            wayland-packages
            kde-packages
            gui-theming-packages
            browser-packages
            network-packages
            fonts-packages
            emacs-packages
            editors-packages
            shell-packages
            gui-app-packages
            typesetting-packages))
   (cons zen-browser-bin custom-home-packages)))

;; WSL2: portable development environment (no X11, no desktop, no browsers)
(define (wsl2-packages)
  (append
   (specifications->packages
    (append programming-packages
            cli-utilities-packages
            fonts-packages
            emacs-packages
            editors-packages
            shell-packages
            typesetting-packages))
   custom-home-packages))
