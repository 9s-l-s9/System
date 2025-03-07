(define-module (home-configuration)
  #:use-module (git-home-service)
  #:use-module (lem-home-service)
  #:use-module (stumpwm-test)
  #:use-module (gnu)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages text-editors)
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

(define guile-setup
  '("guile-ts"
    "guile-lsp-server"
    ))

(define web-packages
  '("nyxt"
    "zen-browser-bin"
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
    ;"emacs-dired-preview"
    "emacs-diredfl"
    "emacs-doom-themes"
    "emacs-eat"
    "emacs-ebib"
    "emacs-ef-themes"
    "emacs-elisp-demos"
    "emacs-engrave-faces"
    ;;"emacs-eshell-did-you-mean"
    ;;"emacs-eshell-prompt-extras"
    ;;"emacs-eshell-syntax-highlighting"
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
    ;; "emacs-nano-modeline"
    "emacs-next"
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
    "emacs-vertico"
    ))

(define app-packages
  '("inkscape"
    "gimp"
    "yt-dlp"
    "lem"
    "fish"
    ;"nushell-bin"
    "kitty"
    ;"calibre"
    ;"zotero"
    ))


;; Combine all package groups
(define all-packages
  (append programming-packages
	  guile-setup
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
   (service home-bash-service-type
            (home-bash-configuration
	    (environment-variables
	     `(("GUILE_LOAD_PATH"
		. ,(string-join '("$XDG_CONFIG_HOME/guix/current/share/guile/site/3.0"
				  "$HOME/.guix-home/profile/share/guile/site/3.0")
				":"))
	       ("GUILE_LOAD_COMPILED_PATH"
		. ,(string-join '("$HOME/.guix-home/profile/lib/guile/3.0/site-ccache"
				  "$XDG_CONFIG_HOME/guix/current/lib/guile/3.0/site-ccache")
				":"))
	       ("GUIX_LOCPATH" . "$HOME_ENVIRONMENT/profile/lib/locales")
	       ("LD_LIBRARY_PATH" . "/usr/lib/cuda-11.2/lib64:$LD_LIBRARY_PATH")))

            (aliases
             '(("ls" . "ls -p --color=auto")
               ("ll" . "ls -l")
               ("grep" . "grep --color=auto")
               ("gh" . "guix home reconfigure ~/Projects/System/home/home-configuration.scm")
               ("gs" . "sudo guix system reconfigure ~/Projects/System/systems/$(hostname).scm")
               ("alire-shell" . "guix shell --container --network --emulate-fhs git bash alire-bin curl coreutils nss-certs tar gzip --share=$HOME=$HOME")))
            ))

   (service home-stumpwm-service-type
         (home-stumpwm-configuration
          (package stumpwm)
          (stumpwm-modules (list sbcl-stumpwm-swm-gaps))
	  (prefix-key "Print")
	  (config
           (list
	    #~"(load \".config/stumpwm/dashboard.lisp\")"
	    #~"(load \".config/stumpwm/internet.lisp\")"
	    #~"(load \".config/stumpwm/screenshot.lisp\")"
	    #~"(load \".config/stumpwm/misc.lisp\")"
            #~"(asdf:load-system \"stumpwm\")"
            #~";; avoid repeating stumpwm:define-key or stumpwm:kbd instead of simply define-key and kbd."
            #~"(in-package :stumpwm)"
            #~"(defvar guix-home-path \"~/.guix-home/profile/share/\""
            #~"  \"Define Guix Home profile PATH.\")"
            #~"(setf *data-dir* \"~/.local/share/stumpwm\")"
            #~";; Modules"
            #~"(set-module-dir \"/run/current-system/profile/share/common-lisp/sbcl/\")"
            #~"(load \".config/stumpwm/ui.lisp\")"
            #~";; Groups"
            #~"(grename \" I \")"
            #~"(add-group (current-screen) \" II \")"
            #~"(add-group (current-screen) \" III \")"
            #~";; Init"
            #~"(when *initializing*"
            #~"      (run-shell-command \"picom -b\")"
            #~"      (run-shell-command \"feh --bg-fill $(find ~/Projects/images/ -type f | shuf -n 1)\")"
            #~"      (modeline/init)"
            #~"      (swm-gaps:toggle-gaps))"))
	  (keymaps
	   (list
	    ;; Main root-map bindings
	    (stumpwm-keymap
	     (name "root")
	     (map-variable "stumpwm:*root-map*")
	     (bindings
	      (list
               ;; Applications
               (stumpwm-keybinding (key "Return") (command "exec kitty"))
               (stumpwm-keybinding (key "b") (command "exec nyxt"))
               (stumpwm-keybinding (key "e") (command "exec lem -i sdl2"))
               (stumpwm-keybinding (key "r") (command "exec"))
               
               ;; Frame Management
               (stumpwm-keybinding (key "F") (command "float-this"))
               (stumpwm-keybinding (key "n") (command "fnext"))
               (stumpwm-keybinding (key "v") (command "vsplit"))
               (stumpwm-keybinding (key "h") (command "hsplit"))
               (stumpwm-keybinding (key "c") (command "remove-split"))
               
               ;; Window Management
               (stumpwm-keybinding (key "l") (command "windowlist"))
               (stumpwm-keybinding (key "k") (command "kill"))
               (stumpwm-keybinding (key "f") (command "next"))
               (stumpwm-keybinding (key "p") (command "pull"))
               (stumpwm-keybinding (key "m") (command "move-window"))
               (stumpwm-keybinding (key "d") (command "delete-window"))
               
               ;; Group Management
               (stumpwm-keybinding (key "G") (command "gnew"))
               (stumpwm-keybinding (key "g") (command "gnext"))
               
               ;; Start/Shutdown
               (stumpwm-keybinding (key "R") (command "loadrc"))
               (stumpwm-keybinding (key "Q") (command "shutdown"))
               
               ;; Custom commands
               (stumpwm-keybinding (key "t") (command "dashboard"))
               (stumpwm-keybinding (key "T") (command "add-todo")))))
	    
	    ;; Screenshot map
	    (stumpwm-keymap
	     (name "screenshot")
	     (prefix-key "S")
	     (bindings
	      (list
               (stumpwm-keybinding (key ".") (command "screenshot"))
               (stumpwm-keybinding (key ",") (command "get-latex")))))
	    
	    ;; Misc map
	    (stumpwm-keymap
	     (name "misc")
	     (map-variable "*misc-map*")
	     (prefix-key "P")
	     (bindings
	      (list
               (stumpwm-keybinding (key "s") (command "browser-search"))
               (stumpwm-keybinding (key "i") (command "internet-10-min"))
               (stumpwm-keybinding (key "t") (command "insert-timestamp")))))))
	  ))
   
(service home-lem-service-type
         (home-lem-configuration
          (package lem)
          ;; Add any additional modules if needed
          ;; (lem-modules (list some-lem-module))
          (config
           (list
            #~"(in-package :lem-user)"
            #~"(load-theme \"black-metal-bathory\")"
            #~"(defvar *sls-main-keymap*"
            #~"  (make-keymap :name '*sls-main-keymap*)"
            #~"  \"Private keymap.\")"
            #~"(define-key *sls-main-keymap* \"b\" 'describe-bindings)"
            #~"(define-key *sls-main-keymap* \"f\" 'find-file)"
            #~"(define-key *sls-main-keymap* \"s\" 'save-current-buffer)"
            #~"(define-key *sls-main-keymap* \"q\" 'execute-command)"
            #~"(define-key *sls-main-keymap* \"d\" 'delete-active-window)"
            #~"(define-key *sls-main-keymap* \"t\" 'terminal)"
            #~"(define-key *sls-main-keymap* \"o\" 'lem-core/commands/file:find-file-recursively)"
            #~"(define-key *sls-main-keymap* \"c\" 'copy-region-to-clipboard)"
            #~"(define-key *sls-main-keymap* \"Return\" 'terminal)"
            #~"(define-key *global-keymap* \"F12\" *sls-main-keymap*)"))))

   (service home-git-service-type
	    (home-git-configuration
	     (user.name "s-l-s")
	     (user.email "schmidt.l.samuel@gmail.com")
	     (extra-options
	      '(
		((filter "lfs") 
		 (clean "git-lfs clean -- %f")
		 (smudge "git-lfs smudge -- %f")
		 (process "git-lfs filter-process")
		 (required #t))
		
		(column
		 (ui "auto"))
		
		(branch
		 (sort "-committerdate"))
		
		(tag
		 (sort "version:refname"))
		
		(init
		 (defaultBranch "main"))
		
		(diff
		 (algorithm "histogram")
		 (colorMoved "plain")
		 (mnemonicPrefix #t)
		 (renames #t))
		
		(push
		 (default "simple")
		 (autoSetupRemote #t)
		 (followTags #t))
		
		(fetch
		 (prune #t)
		 (pruneTags #t)
		 (all #t))
		))
	     ))   

   (service home-redshift-service-type
            (home-redshift-configuration
             (location-provider 'manual)
             (daytime-temperature 3500) ; no blue light for me ;) 
             (nighttime-temperature 3000)
             (latitude 35.81)    
             (longitude -0.80))) 

   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files"))))
   )
  )
 )

