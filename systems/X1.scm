(use-modules (gnu)
             (base-system))

;; schemewm is built from the local checkout via its own guix.scm (the
;; crate graph is vendored there, so the build is offline). Set it up
;; first -- vendor/ is gitignored, so after cloning it must be recreated:
;;   git clone https://github.com/9s-l-s9/scheme-wayland-wm ~/Projects/scheme-wayland-wm
;;   cd ~/Projects/scheme-wayland-wm
;;   guix shell -m manifest.scm -- cargo vendor vendor
(define schemewm
  (primitive-load "/home/samuel/Projects/scheme-wayland-wm/guix.scm"))

(operating-system
  (inherit base-system)
  (host-name "X1")

  ;; Add schemewm system-wide so SDDM finds its wayland-session entry in
  ;; /run/current-system/profile/share/wayland-sessions.
  (packages (cons schemewm (operating-system-packages base-system)))

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
