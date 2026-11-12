(define-module (X1)
  #:use-module (guix utils)
  #:use-module (gnu)
  #:use-module (base-system)
  #:use-module (privileged-scripts)
  #:duplicates (merge-generics replace last))

;; The shared selector uses the verified GitHub binary pinned in System.
;; Run make minde-install before reconfiguring on a new PC.
;; MINDE_BUILD_LOCAL=1 explicitly opts into compiling the working checkout.
(define minde
  (primitive-load (string-append (dirname (current-source-directory))
                                 "/minde-package.scm")))

(operating-system
  (inherit base-system)
  (keyboard-layout (keyboard-layout "de" "bone"))
  (host-name "X1")

  ;; Add minde system-wide so SDDM finds its wayland-session entry in
  ;; /run/current-system/profile/share/wayland-sessions.
  (packages (cons minde (operating-system-packages base-system)))

  ;; The damaged keyboard and CPU power controls need root. Install immutable
  ;; programs so passwordless sudo cannot execute edits to the checkout.
  (services (append (privileged-script-services #:keyboard? #t)
                    (operating-system-user-services base-system)))
  (sudoers-file (privileged-sudoers "samuel" #:keyboard? #t))

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
