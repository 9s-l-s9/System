(define-module (base-system)
  #:use-module (gnu)
  #:use-module (srfi srfi-1)
  #:use-module (gnu system nss)
  #:use-module (gnu services pm)
  #:use-module (gnu services xorg)
  #:use-module (gnu services desktop)
  #:use-module (gnu services docker)
  #:use-module (gnu services networking)
  #:use-module (gnu services linux)
  #:use-module (gnu services mcron)
  #:use-module (guix gexp)
  #:use-module (gnu services virtualization)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages suckless)
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
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)

  #:export (base-system))
(use-service-modules desktop xorg)
(use-service-modules desktop)
(use-package-modules certs)
(use-package-modules shells)
(use-service-modules desktop networking ssh xorg cups)


(define-public base-system
  (operating-system
   (host-name "base")
   (timezone "Europe/Berlin")
    (locale "en_US.utf8")

    ;; Use non-free Linux and firmware
    (kernel linux)
    (firmware (list linux-firmware))
    (initrd microcode-initrd)

    ;; Suspend/resume reliability on the T450s (Broadwell + i915).
    ;; mem_sleep_default=deep forces real S3 suspend (not the lighter s2idle
    ;; that leaves the machine warm), and i915.enable_psr=0 disables panel
    ;; self-refresh, which is the usual cause of the display wedging on resume.
    (kernel-arguments (append '("mem_sleep_default=deep" "i915.enable_psr=0")
                              %default-kernel-arguments))

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
			stumpish
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
			xf86-input-wacom
                        i3lock         ;; X locker with image background
                        xss-lock       ;; bridges elogind Lock signal -> i3lock
                        gvfs)         ;; for user mounts
                      %base-packages))

    (services
     (append
      (list
       ;; Registers /etc/pam.d/i3lock so i3lock can authenticate. Without
       ;; this service, i3lock rejects every password (red ring) regardless
       ;; of correctness. setuid lets pam_unix read /etc/shadow; i3lock
       ;; drops privileges after auth.
       (service screen-locker-service-type
                (screen-locker-configuration
                 (name "i3lock")
                 (program (file-append i3lock "/bin/i3lock"))
                 (using-setuid? #t)))
       ;; Compressed swap in RAM. The T450s has 8 GB and no disk swap
       ;; (T450s.scm sets swap-devices to '()), so without this, memory
       ;; pressure goes straight to cache-thrashing and the OOM killer.
       ;; Note: zram cannot back hibernation; that would need real disk swap.
       (service zram-device-service-type
                (zram-device-configuration
                 (size "4G")
                 (compression-algorithm 'zstd)
                 (priority 100)))

       ;; Weekly TRIM (Sunday 04:00) so the SSD learns which blocks are
       ;; free; neither Guix nor the ext4 mount does this by default.
       (service mcron-service-type
                (mcron-configuration
                 (jobs (list #~(job "0 4 * * 0"
                                    (string-append
                                     #$(file-append util-linux "/sbin/fstrim")
                                     " /"))))))

       (service containerd-service-type)
       (service docker-service-type)
       (service bluetooth-service-type
		(bluetooth-configuration
		 (auto-enable? #t)))

       (service cups-service-type
         (cups-configuration
           (web-interface? #t)
           (extensions
             (list cups-filters epson-inkjet-printer-escpr hplip-minimal))))
       (service plasma-desktop-service-type)

       ;(bluetooth-service #:auto-enable? #t)
       )
      (modify-services %desktop-services
       (gdm-service-type config =>
			 (gdm-configuration
			  (inherit config)
			  (xorg-configuration
			   (xorg-configuration
			    (modules (cons* xf86-input-wacom
					    %default-xorg-modules))
			    (extra-config '("Section \"InputClass\"
                           Identifier \"Wacom Tablet\"
                           MatchDevicePath \"/dev/input/event*\"
                           MatchIsTablet \"on\"
                           Driver \"wacom\"
                         EndSection"))))))

      (elogind-service-type config =>
                            (elogind-configuration
                             (inherit config)
                             ;; Lid close suspends (real S3) to actually save
                             ;; power. Resume reliability is handled via the
                             ;; mem_sleep_default=deep + i915.enable_psr=0
                             ;; kernel-arguments above. xss-lock still locks the
                             ;; session around the suspend so it comes back
                             ;; locked. Docked: stay awake.
                             (handle-lid-switch 'suspend)
                             (handle-lid-switch-external-power 'suspend)
                             (handle-lid-switch-docked 'ignore)))

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
