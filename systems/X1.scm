(use-modules (gnu)
             (base-system))

;; The shared selector defaults to the working checkout. Set
;; MINDE_RC_ARCHIVE and MINDE_RC_REVISION to test/install the explicit
;; vendored RC artifact without removing the checkout rollback path.
(define minde
  (primitive-load "/home/samuel/Projects/System/minde-package.scm"))

(operating-system
  (inherit base-system)
  (keyboard-layout (keyboard-layout "de" "bone"))
  (host-name "X1")

  ;; Add minde system-wide so SDDM finds its wayland-session entry in
  ;; /run/current-system/profile/share/wayland-sessions.
  (packages (cons minde (operating-system-packages base-system)))

  ;; The internal keyboard is corrosion-damaged; scripts/toggle-internal-keyboard.scm
  ;; kills the whole i8042 controller via sysfs.  Declare the NOPASSWD rule
  ;; here — a hand-written /etc/sudoers.d/internal-kbd does not survive
  ;; reconfigure/reboot on Guix System.
  (sudoers-file
   (plain-file "sudoers"
    (string-append
     "root ALL=(ALL) ALL\n"
     "%wheel ALL=(ALL) ALL\n"
     "samuel ALL=(root) NOPASSWD: "
     "/run/current-system/profile/bin/guile -s /home/samuel/Projects/System/scripts/toggle-internal-keyboard.scm, "
     "/run/current-system/profile/bin/guile -s /home/samuel/Projects/System/scripts/toggle-internal-keyboard.scm on, "
     "/run/current-system/profile/bin/guile -s /home/samuel/Projects/System/scripts/toggle-internal-keyboard.scm off, "
     ;; Low-power toggle from a minde key: script caps CPU freq/cores via
     ;; sysfs, so it must run as root without a password prompt (wm-spawn
     ;; has no terminal to ask on).
     "/run/current-system/profile/bin/guile -s /home/samuel/Projects/System/scripts/low-power-mode.scm\n")))

      (swap-devices (list (swap-space
                        (target (uuid
                                 "ce43f82b-3ad3-449b-a73e-4129acc8c322")))))
  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "38C3-A182"
                                       'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device (uuid
                                  "8c23e653-3b08-4d91-a71f-6279bb946573"
                                  'ext4))
                         (type "ext4")) %base-file-systems))
)
