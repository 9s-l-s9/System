;;; steam.scm --- Steam (nonguix) container tweaks for sharper games
;;;
;;; nonguix runs Steam in a `guix shell --container' whose home is
;;; ~/.local/share/guix-sandbox-home and which only sees Steam's own store
;;; closure.  To upscale Europa Universalis IV with gamescope + FSR (see
;;; packages/gamescope.scm) the container must see gamescope and its
;;; dependencies, so the whole read-only store is shared into it, and a
;;; stable ~/.local/bin/gamescope inside the sandbox home points at the
;;; current build.  The game itself is configured outside this repository:
;;;
;;; - Steam launch option for EU4 (skips the Paradox launcher):
;;;     eval $HOME/.local/bin/gamescope -w 1706 -h 960 -W 2560 -H 1440 -F fsr -f
;;;       -- $(echo "%command%" | sed 's#/dowser#/eu4#')
;;; - EU4 pdx_settings.txt: display_mode borderless_fullscreen, 1706x960;
;;;   settings.txt: size 1706x960, game_ui_scale=1.000.
;;;
;;; 1706x960 at UI scale 1.0 gives the same UI size as 2560x1440 at 1.5, but
;;; the bitmap fonts are drawn 1:1 and FSR sharpens the upscale.

(define-module (services steam)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:use-module (packages gamescope)
  #:export (steam-services))

(define (steam-services)
  (list
   (simple-service 'steam-sandbox-store
                   home-environment-variables-service-type
                   ;; Read by nonguix's container wrapper as extra --share.
                   '(("GUIX_SANDBOX_EXTRA_SHARES" . "/gnu/store")))
   (simple-service 'steam-sandbox-gamescope
                   home-files-service-type
                   `((".local/share/guix-sandbox-home/.local/bin/gamescope"
                      ,(file-append gamescope "/bin/gamescope"))))))
