(define-module (packages base-packages)
  #:use-module (gnu packages)
  #:export (all-packages)
  #:export (programming-packages)
  #:export (web-packages)
  #:export (xorg-packages)
  #:export (utilities-packages)
  )

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

(define web-packages
  (list ;;"nyxt"
   ;;"google-chrome-beta"
   "zen-browser-bin"
   "bitwarden-desktop"
        "openssh"
        "network-manager"
        "network-manager-openvpn"))

(define utilities-packages
  (list "tree" "curl" "adb"
	"rsync" "wireplumber" "zip" "unzip" "dnsmasq" "hostapd"
        "glibc-locales" "mpv" "ark" "flatpak" "ripgrep" "git-lfs"))

(define wayland-packages
  (list "gammastep" "mako" "fuzzel"))

(define xorg-packages
  (list
   ;; "rofi" Just using stumpwm :) 
   "dunst" "spectacle" "kmix" "xrandr" "arandr" "feh" "picom" "redshift" "xdg-desktop-portal-wlr" "xsel" "xdg-utils"))

(define gui-theming-packages
  (list "breeze-icons" "oxygen-icons" "gtk+"))

(define fonts-packages
  (list "font-ipa-ex" "font-fira-code" "font-jetbrains-mono" "font-iosevka"
        "font-google-roboto" "font-lato" "font-inconsolata" "font-victor-mono"
        "font-fantasque-sans"))

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

(define kde-packages
  (list "dolphin" "kmix" "konsole"))
 
(define app-packages
  (list "steam" "inkscape" "gimp" "yt-dlp" "lem" "fish" "alacritty" "emacs-next" "helix" "typst-bin" "haunt"))

(define (all-packages)
  (specifications->packages
   (append programming-packages
           xorg-packages
	   kde-packages
           web-packages
           utilities-packages
           fonts-packages
           emacs-packages
           app-packages)))
