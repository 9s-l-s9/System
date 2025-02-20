#! /usr/bin/guile -s
!#
(use-modules (ice-9 popen))

(define (run-cmd cmd)
  (let ((status (system cmd)))
    (if (not (zero? status))
        (error "Command failed:" cmd))))

(run-cmd "xsetwacom --set \"Wacom Intuos Pro M Pen eraser\" Rotate cw")
(run-cmd "xsetwacom --set \"Wacom Intuos Pro M Finger touch\" Rotate cw")
(run-cmd "xsetwacom --set \"Wacom Intuos Pro M Pen stylus\" Rotate cw")

