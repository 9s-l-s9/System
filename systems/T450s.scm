(define-module (T450s)
  #:use-module (base-system)
  #:use-module (gnu))

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

 (swap-devices '("/dev/sda2")) ; from default-system
    (bootloader
   (bootloader-configuration
    (bootloader grub-bootloader) ; Specifies the GRUB EFI bootloader.
    (targets (list "/dev/sda")))
   ) ; Specifies the installation target for the bootloader.

    )

