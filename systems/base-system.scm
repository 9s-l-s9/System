(define-module (base-system)
  #:use-module (gnu)
  #:use-module (srfi srfi-1)
  #:use-module (gnu system nss)
  #:use-module (gnu system accounts)
  #:use-module (gnu services pm)
  #:use-module (gnu services xorg)
  #:use-module (gnu services sddm)
  #:use-module (gnu services desktop)
  #:use-module (gnu services containers)
  #:use-module (gnu services sysctl)
  #:use-module (gnu services networking)
  #:use-module (gnu services virtualization)
  #:use-module (gnu services sound)
  #:use-module (gnu services linux)
  #:use-module (gnu services mcron)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages display-managers)
  #:use-module (gnu packages imagemagick)
  #:use-module (guix gexp)
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


;; Shared Xorg configuration (Wacom tablet support), used by the display
;; manager so the greeter's X server matches the session's.
;; NOTE: do not put keyboard-layout de/bone here — tried 2026-07-07, it broke
;; password entry at the greeter and the dead-keyboard bug turned out to be
;; key-event *delivery* (grab-shaped), not layout.
(define %xorg-wacom-configuration
  (xorg-configuration
   (modules (cons* xf86-input-wacom
                   %default-xorg-modules))
   (extra-config '("Section \"InputClass\"
                           Identifier \"Wacom Tablet\"
                           MatchDevicePath \"/dev/input/event*\"
                           MatchIsTablet \"on\"
                           Driver \"wacom\"
                         EndSection"))))

;; SDDM login background: a wallpaper from ~/Projects/images, copied into
;; the store at build time so the (unprivileged) sddm user can read it.
;; Swap the image by changing this path and reconfiguring.
(define %sddm-background
  (local-file "/home/samuel/Projects/images/Bentheim_Forest.png"
              "sddm-background.png"))

;; SDDM has no standalone background setting; the background belongs to the
;; theme. This takes the bundled "maldives" theme and swaps its background
;; for %sddm-background. Three Qt6-SDDM quirks: relative paths in theme.conf
;; resolve against SddmComponents (not the theme dir), so the path must be
;; absolute; the greeter has no WebP plugin, so convert to real PNG (some
;; files in ~/Projects/images are WebP despite their extension); and themes
;; must declare QtVersion=6 in metadata.desktop or the daemon demands the
;; Qt5 sddm-greeter binary, which Guix's Qt6-only build lacks, and silently
;; falls back to the embedded default theme (bug shared by all bundled
;; themes on Guix).
(define %sddm-custom-theme
  (computed-file
   "sddm-custom-themes"
   (with-imported-modules '((guix build utils))
     #~(begin
         (use-modules (guix build utils))
         (let* ((theme (string-append #$output "/custom"))
                (bg (string-append theme "/sddm-background.png")))
           (mkdir-p #$output)
           (copy-recursively #$(file-append sddm "/share/sddm/themes/maldives")
                             theme)
           (for-each make-file-writable (find-files theme))
           (invoke #$(file-append imagemagick "/bin/convert")
                   #$%sddm-background bg)
           (substitute* (string-append theme "/theme.conf")
             (("^background=.*")
              (string-append "background=" bg "\n")))
           (substitute* (string-append theme "/metadata.desktop")
             (("^\\[SddmGreeterTheme\\]")
              "[SddmGreeterTheme]\nQtVersion=6")))))))

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
                                          "cgroup"   ;; rootless podman: cgroup-v2 delegation
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
                        bluez          ;; bluetoothctl; the daemon comes from
                                       ;; bluetooth-service-type below. Audio
                                       ;; routing is PipeWire's job (Guix Home
                                       ;; home-pipewire-service-type), so no
                                       ;; bluez-alsa here.
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

       ;; Rootless Podman instead of Docker (2026-07): dockerd + containerd
       ;; sat resident on an 8 GB machine and slowed boot for a tool used
       ;; occasionally; podman is daemonless so its idle cost is zero. Needs
       ;; the "cgroup" group membership above plus subuid/subgid ranges.
       ;; Old /var/lib/docker state is orphaned by the switch -- delete it
       ;; to reclaim disk once nothing in it is still wanted.
       (service rootless-podman-service-type
                (rootless-podman-configuration
                 (subgids (list (subid-range (name "samuel"))))
                 (subuids (list (subid-range (name "samuel"))))))

       ;; TLP had been a package (inert) since the beginning; the service is
       ;; what applies a policy. Intent here: full performance on AC and *no
       ;; performance regression on battery* -- every TLP default that trades
       ;; performance for runtime is overridden (core parking, EPB powersave,
       ;; SATA min_power, wifi/sound powersave, USB autosuspend). Remaining
       ;; battery savings come only from knobs whose latency cost is below
       ;; perception (SATA DIPM, PCIe ASPM).
       (service tlp-service-type
                (tlp-configuration
                 (cpu-scaling-governor-on-ac (list "performance"))
                 ;; intel_pstate "powersave" is the kernel default this
                 ;; machine already runs: dynamic scaling, instant ramp-up.
                 (cpu-scaling-governor-on-bat (list "powersave"))
                 (cpu-boost-on-ac? #t)
                 (cpu-boost-on-bat? #t)
                 (sched-powersave-on-bat? #f)   ;; default #t parks cores on battery
                 (energy-perf-policy-on-bat "performance") ;; default "powersave"
                 (cpu-energy-perf-policy-on-ac "performance")
                 (cpu-energy-perf-policy-on-bat "performance")
                 (sata-linkpwr-on-bat "med_power_with_dipm") ;; default min_power adds I/O latency
                 (disk-apm-level-on-bat (list "254" "254"))  ;; default 128; moot on SSDs but explicit
                 (wifi-pwr-on-bat? #f)          ;; default #t causes wifi latency spikes
                 (sound-power-save-on-bat 0)    ;; default 1s HDA suspend pops/delays audio
                 (runtime-pm-on-bat "on")       ;; default "auto" adds PCIe wake latency
                 (usb-autosuspend? #f)))        ;; external keyboard/BT must never sleep
       ;; The 15 W Broadwell in this thin chassis thermal-throttles under
       ;; sustained load; thermald manages the envelope proactively so turbo
       ;; degrades gradually instead of collapsing at the trip point.
       (service thermald-service-type)
       (service bluetooth-service-type
		(bluetooth-configuration
		 (auto-enable? #t)))

       (service cups-service-type
         (cups-configuration
           (web-interface? #t)
           (extensions
             (list cups-filters epson-inkjet-printer-escpr hplip-minimal))))
       (service plasma-desktop-service-type)

       ;; SDDM instead of GDM (removed from %desktop-services below):
       ;; themeable login manager; "custom" is maldives with our wallpaper.
       (service sddm-service-type
                (sddm-configuration
                 (theme "custom")
                 (themes-directory %sddm-custom-theme)
                 ;; Guix defaults Numlock=on (upstream default is none). The
                 ;; locked Mod2 carries into X11 sessions and stumpwm's key
                 ;; grabs stop matching -- the "keyboard dead in stumpwm,
                 ;; mouse fine" bug (diagnosed 2026-07-07 via xinput test-xi2:
                 ;; every key event arrived with "modifiers: locked 0x10").
                 (numlock "none")
                 (xorg-configuration %xorg-wacom-configuration)))

       )
      (modify-services %desktop-services
      (delete gdm-service-type)

      ;; VM tuning for the zram-swap setup; the kernel defaults assume disk
      ;; swap. page-cluster 0 drops the 8-page swap-in readahead that only
      ;; amortises seeks on rotating disks; swappiness 150 (>100) tells the
      ;; kernel zram I/O is cheaper than dropping file cache. dirty_bytes
      ;; caps write-back buffering at 256 MB (default is 20% of RAM ~1.6 GB)
      ;; so bulk writes (guix gc, image pulls) stop stalling the desktop
      ;; behind a SATA flush.
      (sysctl-service-type config =>
                           (sysctl-configuration
                            (inherit config)
                            (settings (append
                                       '(("vm.swappiness" . "150")
                                         ("vm.page-cluster" . "0")
                                         ("vm.dirty_bytes" . "268435456")
                                         ("vm.dirty_background_bytes" . "67108864"))
                                       %default-sysctl-settings))))

      ;; PipeWire (via home-pipewire-service-type in base-home.scm) owns
      ;; audio, including Bluetooth. Keep pulseaudio-service-type for the
      ;; ALSA glue it sets up, but stop the real PulseAudio daemon from
      ;; autospawning and stealing devices from pipewire-pulse.
      (pulseaudio-service-type config =>
                               (pulseaudio-configuration
                                (inherit config)
                                (client-conf '((autospawn . no)))))

      (elogind-service-type config =>
                            (elogind-configuration
                             (inherit config)
                             ;; Keep long-running jobs alive even when the lid
                             ;; closes. Manual suspend remains available, but
                             ;; elogind no longer initiates it implicitly.
                             (handle-lid-switch 'ignore)
                             (handle-lid-switch-external-power 'ignore)
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
