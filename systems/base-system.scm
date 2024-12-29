(define-module (systems base-system)
  #:use-module (gnu)
  #:use-module (srfi srfi-1)
  #:use-module (gnu system nss)
  #:use-module (gnu services pm)
  #:use-module (gnu services desktop)
  #:use-module (gnu services docker)
  #:use-module (gnu services networking)
  #:use-module (gnu services virtualization)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages file-systems)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages mtools)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages gnuzilla)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages web-browsers)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages package-management)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)

  #:export (base-system)
)

(use-service-modules desktop xorg)
(use-package-modules certs)
(use-package-modules shells)


(define-public base-system
  (operating-system
   (host-name "base")
   (timezone "Europe/Berlin")
    (locale "en_US.utf8")

    ;; Use non-free Linux and firmware
    (kernel linux)
    (firmware (list linux-firmware))
    (initrd microcode-initrd)

    ;; Special german keyboard layout
    ;; No longer really needed because of external corne keyboard
    ;;(keyboard-layout (keyboard-layout "de" "bone"))

    ;; Guix doesn't like it when there isn't a file-systems/bootloader
    ;; entry, so add one that is meant to be overridden
     (bootloader (bootloader-configuration
              (bootloader grub-efi-bootloader)
              (targets '("/boot/efi"))
	      ))

    (file-systems (cons*
                   (file-system
                     (mount-point "/tmp")
                     (device "none")
                     (type "tmpfs")
                     (check? #f))
                   %base-file-systems))

    (users (cons (user-account
                  (name "samuel")
                  (comment "Samuel")
                  (group "users")
                  (home-directory "/home/samuel")
                  (supplementary-groups '(
                                          "wheel"     ;; sudo
                                          "netdev"    ;; network devices
                                          "kvm"
                                          "tty"
                                          "input"
                                          "docker"
                                          "realtime"  ;; Enable realtime scheduling
                                          "lp"        ;; control bluetooth devices
                                          "audio"     ;; control audio devices
                                          "video")))  ;; control video devices

                 %base-user-accounts))

    ;; Add the 'realtime' group
    (groups (cons (user-group (system? #t) (name "realtime"))
                  %base-groups))


    ;; Install bare-minimum system packages
    (packages (append (list
                        git
                        ntfs-3g
                        exfat-utils
                        fuse-exfat
			
			;; Stumpwm
			sbcl
			stumpwm
			sbcl-stumpwm-swm-gaps

                        ;; Sway
                        ;; sway
                        ;; swaybg
                        ;; swayidle
                        ;; swaylock

			xterm
                        bluez
                        bluez-alsa
			pipewire
                        tlp
                        xf86-input-libinput
                        gvfs)         ;; for user mounts
                      %base-packages))

    (services
     (append
      (list
       (service containerd-service-type)
       (service docker-service-type)
       (service bluetooth-service-type
		(bluetooth-configuration
		 (auto-enable? #t)))
       ;(service gnome-desktop-service-type)

       ;(bluetooth-service #:auto-enable? #t)
       )
      ;; Modify services from old system.scm
      (modify-services %desktop-services

                       (guix-service-type config => (guix-configuration
                                                     (inherit config)
                                                     (substitute-urls
                                                      (append (list "https://substitutes.nonguix.org")
                                                              %default-substitute-urls))
                                                     (authorized-keys
                                                      (append (list (plain-file "non-guix.pub"
										"(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))
                                                              %default-authorized-guix-keys)))))

      ))

    ;; Allow resolution of '.local' host names with mDNS
    (name-service-switch %mdns-host-lookup-nss)))
