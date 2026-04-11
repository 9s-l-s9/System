#!/usr/bin/env -S guile -s
!#

(use-modules (ice-9 popen))

(define xrdb-config
  "Xft.dpi: 192
Xft.antialias: true
Xft.rgba: rgb
Xft.hinting: true
Xft.hintstyle: hintslight
")

(define (main)
  (let ((port (open-pipe* OPEN_WRITE "xrdb" "-merge" "-")))
    (display xrdb-config port)
    (let ((status (close-pipe port)))
      (if (zero? status)
          (exit 0)
          (exit 1)))))

(main)
