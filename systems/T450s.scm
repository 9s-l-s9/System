(use-modules (base-system)
             (gnu bootloader)
             (gnu bootloader grub)
             (gnu system)
             (gnu system file-systems)
             (gnu system keyboard))

;; schemewm is built from the local checkout via its own guix.scm (the
;; crate graph is vendored there, so the build is offline). The file's
;; last expression is the package object; primitive-load hands it back.
(define schemewm
  (primitive-load "/home/samuel/Projects/scheme-wayland-wm/guix.scm"))

(operating-system
  (inherit base-system)
  (keyboard-layout (keyboard-layout "de" "bone"))
  (host-name "T450s")

  ;; Add schemewm system-wide so SDDM finds its wayland-session entry in
  ;; /run/current-system/profile/share/wayland-sessions.
  (packages (cons schemewm (operating-system-packages base-system)))

  (file-systems
   (append
    (list (file-system
           (device (uuid "bbd2fd05-4888-45bc-bc6f-714b4245289c"))
           (mount-point "/")
           (type "ext4")))
    %base-file-systems))

  ;; /dev/sda2, re-initialised with mkswap 2026-07-08 (it used to carry a
  ;; stale swsuspend signature that made shepherd fail to swapon during
  ;; reconfigure). Priority 10 keeps it strictly a spill-over behind the
  ;; zram device (priority 100, base-system.scm): pages land here only when
  ;; compressed RAM is exhausted, instead of waking the OOM killer.
  (swap-devices (list (swap-space
                       (target (uuid "7f8c9350-eb0c-4ee4-9249-033923569373"))
                       (priority 10)
                       (discard? #t))))

  (bootloader
   (bootloader-configuration
    (bootloader grub-bootloader)
    (targets (list "/dev/sda")))))
