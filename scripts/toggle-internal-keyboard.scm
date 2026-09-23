#!/usr/bin/env -S guile -s
!#
;;; Toggle the corrosion-damaged internal keyboard by binding/unbinding the
;;; whole i8042 controller.  serio drvctl is not enough: bind_mode=auto
;;; re-attaches atkbd right away, and the damaged keys keep firing.
;;;
;;; Usage: toggle-internal-keyboard.scm [on|off]   (no argument toggles)
;;;
;;; Must run as root.  systems/X1.scm grants a NOPASSWD sudo rule for
;;; exactly this script so the minde key (Print t) can call it via sudo.

(use-modules (ice-9 format))

(define driver-dir "/sys/bus/platform/drivers/i8042")
(define device "i8042")
(define bound? (file-exists? (string-append driver-dir "/" device)))

(define (match-arg args)
  (cond ((null? args) (not bound?))
        ((string=? (car args) "on") #t)
        ((string=? (car args) "off") #f)
        (else (format (current-error-port)
                      "usage: toggle-internal-keyboard.scm [on|off]~%")
              (exit 2))))

(define want-enabled?
  (match-arg (cdr (command-line))))

(when (eq? want-enabled? bound?)
  (format #t "Internal keyboard already ~a.~%"
          (if bound? "enabled" "disabled"))
  (exit 0))

(define control-path
  (string-append driver-dir (if want-enabled? "/bind" "/unbind")))

(catch #t
  (lambda ()
    (call-with-output-file control-path
      (lambda (port) (display device port)))
    (format #t "Internal keyboard ~a.~%"
            (if want-enabled? "enabled" "disabled")))
  (lambda (key . args)
    (format (current-error-port)
            "toggle-internal-keyboard: could not write ~a: ~s ~s (run as root?)~%"
            control-path key args)
    (exit 1)))
