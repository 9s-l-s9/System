#!/usr/bin/env -S guile -e main -s
!#

(use-modules (ice-9 popen)
             (ice-9 getopt-long))

(define (run-cmd cmd)
  (let ((status (system cmd)))
    (if (not (zero? status))
        (error "Command failed:" cmd))))

(define (setup-samsung-monitor)
  (display "Setting up Samsung Monitor...\n")
  (run-cmd "xrandr --output eDP-1 --primary --mode 1920x1080 --pos 2560x360 --rotate normal --output DP-1 --off --output HDMI-1 --off --output DP-2 --off --output HDMI-2 --mode 2560x1440 --pos 0x0 --rotate normal")
  (display "Setup finished")

(define (setup-wacom-intuos)
  (display "Setting up Wacom Intuos Pro...\n")
  (run-cmd "xsetwacom --set \"Wacom Intuos Pro M Pen eraser\" Rotate cw")
  (run-cmd "xsetwacom --set \"Wacom Intuos Pro M Finger touch\" Rotate cw")
  (run-cmd "xsetwacom --set \"Wacom Intuos Pro M Pen stylus\" Rotate cw")
  (display "Setup finished"))

(define (show-usage)
  (display "Usage: setup-devices.scm [OPTION]\n")
  (display "Set up devices based on selection.\n\n")
  (display "  --samsung-monitor    Set up Samsung monitor\n")
  (display "  --wacom-intuos       Set up Wacom Intuos Pro\n")
  (display "  --help               Display this help and exit\n"))

(define (main args)
  (let* ((option-spec '((samsung-monitor (single-char #\s))
                        (wacom-intuos (single-char #\w))
                        (help (single-char #\h))))
         (options (getopt-long args option-spec))
         (help-wanted (option-ref options 'help #f))
         (samsung-wanted (option-ref options 'samsung-monitor #f))
         (wacom-wanted (option-ref options 'wacom-intuos #f)))
    
    (cond
     (help-wanted
      (show-usage))
     (samsung-wanted
      (setup-samsung-monitor))
     (wacom-wanted
      (setup-wacom-intuos))
     (else
      (show-usage)))))
