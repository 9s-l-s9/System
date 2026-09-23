#!/usr/bin/env guile
!#
;;; eco-toggle.scm --- Toggle eco mode while agents keep running
;;;
;;; First invocation enters eco mode, second one restores everything:
;;;   - screen backlight to 0% (previous level is remembered)
;;;   - Bluetooth rfkill-blocked
;;; Wi-Fi and CPU performance stay untouched: never trade performance for
;;; battery, on battery or not (see tlp-configuration in base-system.scm).
;;; Bound to the minde prefix key "h" (services/minde.scm, "eco mode").
;;;
;;; Usage: eco-toggle.scm [on|off]   (no argument toggles)
;;;
;;; The minde autostart runs `eco-toggle.scm off` at every login.  The
;;; ThinkPad firmware remembers the Bluetooth kill switch across reboots,
;;; so an eco session ended by a reboot would otherwise leave Bluetooth
;;; silently blocked (the autostart restores brightness, so nothing looks
;;; like eco mode), and the state file would then invert the toggle.

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 format))

(define state-file
  (string-append (or (getenv "XDG_CACHE_HOME")
                     (string-append (getenv "HOME") "/.cache"))
                 "/eco-mode-state"))

(define (system-output cmd)
  (let* ((port (open-input-pipe cmd))
         (output (read-line port)))
    (close-pipe port)
    (if (eof-object? output) "" (string-trim-both output))))

(define (try cmd)
  "Run CMD, return #t on success; never throw."
  (zero? (status:exit-val (system cmd))))

(define (enter-eco!)
  (let ((brightness (system-output "brightnessctl get")))
    (call-with-output-file state-file
      (lambda (port) (display brightness port))))
  (try "brightnessctl set 0%")
  (try "rfkill block bluetooth 2>/dev/null")
  (format #t "eco: on~%"))

(define (leave-eco!)
  "Restore everything.  Idempotent: safe to run when eco mode is not on."
  (let ((brightness (false-if-exception
                     (call-with-input-file state-file read-line))))
    (when (file-exists? state-file)
      (try (format #f "brightnessctl set ~a"
                   (if (and (string? brightness)
                            (not (string-null? brightness)))
                       brightness
                       "60%")))
      (delete-file state-file))
    ;; Always unblock: the block may have outlived the state file (reboot).
    (try "rfkill unblock bluetooth 2>/dev/null"))
  (format #t "eco: off~%"))

(define eco-on? (file-exists? state-file))

(let ((args (cdr (command-line))))
  (cond ((null? args) (if eco-on? (leave-eco!) (enter-eco!)))
        ((string=? (car args) "off") (leave-eco!))
        ((string=? (car args) "on") (unless eco-on? (enter-eco!)))
        (else (format (current-error-port) "usage: eco-toggle.scm [on|off]~%")
              (exit 2))))
