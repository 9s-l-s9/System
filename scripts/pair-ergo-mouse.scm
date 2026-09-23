#!/usr/bin/env -S guile -s
!#
;;; Re-pair the Logitech ERGO M575 trackball.
;;;
;;; Once the mouse has been paired with another computer it comes back with
;;; a fresh Bluetooth address and refuses the old bond, so "connect" never
;;; works again and every attempt leaves another stale "ERGO M575" entry.
;;; This script: unblocks Bluetooth (eco mode rfkills it), removes all stale
;;; M575 bonds, scans for the mouse (put it in pairing mode first), then
;;; pairs with a registered agent (pairing without one fails with
;;; AuthenticationFailed), trusts and connects it.
;;;
;;; Usage: pair-ergo-mouse.scm [NAME]   (NAME defaults to "ERGO M575")

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 format)
             (ice-9 regex)
             (srfi srfi-1))

(define mouse-name
  (let ((args (cdr (command-line))))
    (if (pair? args) (car args) "ERGO M575")))

(define (notify title body)
  (system* "notify-send" title body)
  (format #t "~a: ~a~%" title body))

(define (read-all port)
  (let loop ((lines '()))
    (let ((line (read-line port)))
      (if (eof-object? line)
          (reverse lines)
          (loop (cons line lines))))))

(define (bluetoothctl . args)
  "Run one non-interactive bluetoothctl command, returning its output lines."
  (let* ((port (apply open-pipe* OPEN_READ "timeout" "10" "bluetoothctl" args))
         (lines (read-all port)))
    (close-pipe port)
    lines))

(define (bluetoothctl-session script seconds)
  "Feed SCRIPT to an interactive bluetoothctl (needed for the pairing agent)
and let it run for SECONDS.  Returns the output lines."
  (let* ((cmd (format #f "{ printf '~a'; sleep ~a; } | timeout ~a bluetoothctl 2>&1"
                      script seconds (+ seconds 5)))
         (port (open-input-pipe cmd))
         (lines (read-all port)))
    (close-pipe port)
    lines))

(define (mouse-addresses)
  (filter-map
   (lambda (line)
     (let ((m (string-match "^Device ([0-9A-F:]{17}) (.*)$" line)))
       (and m
            (string=? (match:substring m 2) mouse-name)
            (match:substring m 1))))
   (bluetoothctl "devices")))

(define (connected? addr)
  (any (lambda (l) (string-contains l "Connected: yes"))
       (bluetoothctl "info" addr)))

;; 1. Radio on.
(system* "rfkill" "unblock" "bluetooth")
(bluetoothctl "power" "on")

;; 2. Drop every stale bond for this mouse.
(let ((stale (mouse-addresses)))
  (for-each (lambda (a) (bluetoothctl "remove" a)) stale)
  (format #t "Removed ~a stale ~a pairing(s).~%" (length stale) mouse-name))

;; 3. Scan until the mouse shows up (pairing mode blinks ~3 min).
(notify "Mouse" (string-append "Put the " mouse-name " in pairing mode; scanning..."))
(define addr
  (let loop ((tries 0))
    (bluetoothctl-session "scan on\\n" 10)
    (let ((found (mouse-addresses)))
      (cond ((pair? found) (car found))
            ((>= tries 5)
             (notify "Mouse" (string-append mouse-name " not found."))
             (exit 1))
            (else (loop (+ tries 1)))))))

(format #t "Found ~a at ~a.~%" mouse-name addr)

;; 4. Pair with an agent, trust, connect.
(bluetoothctl-session
 (format #f "agent KeyboardDisplay\\ndefault-agent\\nscan on\\npair ~a\\n" addr)
 15)
(bluetoothctl "trust" addr)
(bluetoothctl "connect" addr)
(sleep 2)

(if (connected? addr)
    (notify "Mouse" (string-append mouse-name " connected."))
    (begin
      (notify "Mouse" (string-append mouse-name " pairing failed."))
      (exit 1)))
