(use-modules (gnu)
             (base-system))


(operating-system
  (inherit base-system)
  (host-name "X1")    
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
