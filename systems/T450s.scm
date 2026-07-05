(use-modules (base-system)
             (gnu bootloader)
             (gnu bootloader grub)
             (gnu system)
             (gnu system file-systems)
             (gnu system keyboard))

(operating-system
  (inherit base-system)
  (keyboard-layout (keyboard-layout "de" "bone"))
  (host-name "T450s")

  (file-systems
   (append
    (list (file-system
           (device (uuid "bbd2fd05-4888-45bc-bc6f-714b4245289c"))
           (mount-point "/")
           (type "ext4")))
    %base-file-systems))

  ;; /dev/sda2 currently has a swsuspend signature rather than an active swap
  ;; signature, so declaring it as swap makes shepherd fail during reconfigure.
  (swap-devices '())

  (bootloader
   (bootloader-configuration
    (bootloader grub-bootloader)
    (targets (list "/dev/sda")))))
