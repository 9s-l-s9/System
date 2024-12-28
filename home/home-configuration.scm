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
    "flameshot"
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
  '("emacs-next"
    "emacs-org-present"
    "emacs-htmlize"
    "emacs-imenu-list"
    "emacs-sudo-edit"
    "emacs-ebib"
    "emacs-dashboard"
    "emacs-all-the-icons-completion"
    "emacs-vertico"
    "emacs-marginalia"
    "emacs-markdown-preview-mode"
    "emacs-cape"
    "emacs-corfu"
    "emacs-consult"
    "emacs-org-modern"
    "emacs-org-transclusion"
    "emacs-eat"
    "emacs-ef-themes"
    "emacs-nano-modeline"
    "emacs-rg"
    "emacs-highlight-indent-guides"
    "emacs-telega"
    "emacs-gptel"
    "emacs-magit"
    "emacs-pdf-tools"
    "emacs-undo-tree"
    "emacs-diredfl"
    "emacs-dired-preview"
    "emacs-all-the-icons-dired"
    "emacs-engrave-faces"
    "emacs-popper"
    "emacs-all-the-icons"
    "emacs-elisp-demos"
    "emacs-helpful"
    "emacs-eshell-prompt-extras"
    "emacs-eshell-did-you-mean"
    "emacs-eshell-syntax-highlighting"
    "emacs-focus"
    "emacs-doom-themes"
    "emacs-flycheck"
    "emacs-meow"))

(define app-packages
  '("inkscape"
    "gimp"
    "yt-dlp"
    "lem"
    "nushell-bin"
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
             (daytime-temperature 3500)
             (nighttime-temperature 3000)
             (latitude 35.81)    ; northern hemisphere
             (longitude -0.80))) ; west of Greenwich

   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files"))))
   )
  )
 )

