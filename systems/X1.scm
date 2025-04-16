(define-module (X1)
  #:use-module (gnu)
  #:use-module (base-system)
  )


(operating-system
  (inherit base-system)
  (host-name "X1")    
      (swap-devices (list (swap-space
                        (target (uuid
                                 "03b4094e-fa76-4ae1-85b8-ced35e8a2a97")))))
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
