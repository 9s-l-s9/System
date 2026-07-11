(define-module (packages base-packages)
  #:use-module (gnu packages)
  #:use-module (packages eca)
  #:use-module (packages font-space-mono)
  #:use-module (packages whisper)
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
        ;"r"
        ;"sqlite"
        ;"duckdb"
        ;"gcc-toolchain"
        ))

;; CLI utilities (portable: work everywhere)

(define cli-utilities-packages
  (list "tree" "curl"
        "rsync" "zip" "unzip"
        "glibc-locales" "mpv" "ripgrep" "git-lfs" "yt-dlp"
        "guile-json"                 ; scripts/ask-ai.scm
        "whisper-cpp" "ffmpeg"))   ; local speech-to-text (whisper.el)

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

;; Fonts (portable: needed for Emacs all-the-icons)

(define fonts-packages
  (list "font-ipa-ex" "font-fira-code" "font-jetbrains-mono" "font-iosevka"
        "font-google-roboto" "font-lato" "font-inconsolata" "font-victor-mono"
        "font-fantasque-sans"
        ;; design-skill manual aesthetic: Plex Mono body; Space Mono is custom.
        "font-ibm-plex"))

;; Emacs packages (portable: identical on all machines)

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
   "emacs-dap-mode"
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
   "emacs-gptel"
   "emacs-helpful"
   "emacs-highlight-indent-guides"
   ;"emacs-htmlize"
   "emacs-imenu-list"
   "emacs-magit"
   "emacs-marginalia"
   ;"emacs-markdown-preview-mode"
   "emacs-meow"
   ;; "emacs-minuet"       ; AI inline completion; disabled until an API key exists

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
   "emacs-vertico"
   "emacs-vundo"))

;; Custom packages missing from upstream Guix (package objects, not specs).
(define custom-home-packages
  (list emacs-eca
        emacs-whisper
        font-space-mono))

;; Editors

(define editors-packages
  (list "emacs-next"
        "helix"))

;; Shell

(define shell-packages
  (list "fish"))

;; Terminal emulator (desktop only)

(define terminal-packages
  (list "alacritty"))

;; Typesetting

(define typesetting-packages
  (list "typst-bin"
        "haunt"))

;; X11 / display server

(define xorg-packages
  (list
   ;; "rofi"
   "dunst" "spectacle" "kmix" "xrandr" "arandr"
   "feh" "picom" "redshift" "xset"
   "eww"                              ; desktop widgets (yuck config, driven from StumpWM)
   "xdotool"                          ; type transcription into focused window
   "numlockx"                         ; clear SDDM's forced NumLock at session start
   "brightnessctl"                    ; restore backlight at session start (SDDM,
                                      ; unlike GDM, leaves it wherever elogind
                                      ; restored it -- possibly 0)
   "xdg-desktop-portal-wlr" "xsel" "xdg-utils"))

;; Wayland (defined but not assembled by default)

(define wayland-packages
  (list "gammastep" "mako" "fuzzel" "swaybg" "wl-clipboard"))

;; KDE desktop

(define kde-packages
  (list "dolphin" "kmix" "konsole"))

;; GUI theming

(define gui-theming-packages
  (list "breeze-icons" "oxygen-icons" "gtk+"))

;; GUI apps (desktop only)

(define gui-app-packages
  (list "steam" "inkscape" "gimp"))

;; Browser / passwords

(define browser-packages
  (list "zen-browser-bin"
        "bitwarden-desktop"))

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
            xorg-packages
	    wayland-packages
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
            typesetting-packages))
   custom-home-packages))

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
