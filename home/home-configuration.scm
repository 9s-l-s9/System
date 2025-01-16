(define-module (home home-configuration)
  #:use-module (gnu)
  #:use-module (gnu home)
  #:use-module (gnu home services dotfiles)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services shells))

(define programming-packages
  '("python"
    ;"r"
    ;"sqlite"
    ;"duckdb"
    ;"gcc-toolchain"
    ))

(define web-packages
  '("nyxt"
    "google-chrome-beta"
    "openssh"
    "network-manager"
    "network-manager-openvpn"
    ;"syncthing"
    ))

(define system-utilities
  '(
    "wireplumber"
    "feh"
    "zip"
    "unzip"
    "dnsmasq"
    "hostapd"
    "glibc-locales"
    ;"file"
    "mpv"
    ;"gvfs"
    "ark"
    "unrar"
    ;"socat"
    "flatpak"
    ;"dash"
    "ripgrep"
    ;"acpi"
    "git-lfs"
    ;"stow"
    ;"udiskie"
    ))

(define wayland-packages
  '(
    "gammastep"
    "mako"
    "fuzzel"
    ))


(define x-packages
  '(
    "rofi"
    "dunst"
    "spectacle"
    "kmix"
    "xrandr"
    "picom"
    "redshift"
    "xdg-desktop-portal-wlr"
    ))


(define gui-theming-packages
  '("breeze-icons"
    "oxygen-icons"
    "gtk+"
    ))

(define fonts-packages
  '("font-ipa-ex"
    "font-fira-code"
    "font-jetbrains-mono"
    "font-iosevka"
    "font-google-roboto"
    "font-lato"
    "font-inconsolata"
    "font-victor-mono"
    "font-fantasque-sans"))

(define emacs-packages
  '(
    "emacs-all-the-icons"
    "emacs-all-the-icons-completion"
    "emacs-all-the-icons-dired"
    "emacs-avy"
    "emacs-cape"
    "emacs-consult"
    "emacs-corfu"
    "emacs-dashboard"
    "emacs-dired-preview"
    "emacs-diredfl"
    "emacs-doom-themes"
    "emacs-eat"
    "emacs-ebib"
    "emacs-ef-themes"
    "emacs-elisp-demos"
    "emacs-engrave-faces"
    "emacs-eshell-did-you-mean"
    "emacs-eshell-prompt-extras"
    "emacs-eshell-syntax-highlighting"
    "emacs-flycheck"
    "emacs-focus"
    "emacs-gptel"
    "emacs-helpful"
    "emacs-highlight-indent-guides"
    "emacs-htmlize"
    "emacs-imenu-list"
    "emacs-magit"
    "emacs-marginalia"
    "emacs-markdown-preview-mode"
    "emacs-meow"
    "emacs-nano-modeline"
    "emacs-next"
    "emacs-orderless"
    "emacs-org-modern"
    "emacs-org-present"
    "emacs-org-transclusion"
    "emacs-pdf-tools"
    "emacs-popper"
    "emacs-rg"
    "emacs-sudo-edit"
    "emacs-telega"
    "emacs-undo-tree"
    "emacs-vertico"
    ))

(define app-packages
  '("inkscape"
    "gimp"
    "yt-dlp"
    "lem"
    "nushell-bin"
    "kitty"
    ;"calibre"
    ;"zotero"
    ))


;; Combine all package groups
(define all-packages
  (append programming-packages
	  x-packages
          web-packages
          system-utilities
          fonts-packages
          emacs-packages
          app-packages
	  ))

(home-environment
 (packages (specifications->packages all-packages))
 (services
  (list
   ;; (service home-bash-service-type
            ;; (home-bash-configuration
            ;;  (aliases '())
            ;;  (bashrc (list (local-file "../.config/.bashrc" )))))

   (service home-redshift-service-type
            (home-redshift-configuration
             (location-provider 'manual)
             (daytime-temperature 3500) ; just no bluelight a tall
             (nighttime-temperature 3000)
             (latitude 35.81)    
             (longitude -0.80))) 

   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files"))))
   )
  )
 )

