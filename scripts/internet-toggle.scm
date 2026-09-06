#!/usr/bin/env guile
!#

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (srfi srfi-1))

;; Helper function to run a shell command and get its output
(define (system-output cmd)
  (let* ((port (open-input-pipe cmd))
         (output (read-line port)))
    (close-pipe port)
    output))

;; Function to toggle Wi-Fi on or off
(define (toggle-internet)
  "Toggle Wi-Fi on or off. Needs nmcli."
  (let ((status (system-output "nmcli -t -f WIFI radio")))
    ;; Remove any trailing whitespace/newlines
    (set! status (string-trim-both status))
    (if (string=? status "enabled")
        (system "nmcli radio wifi off")
        (system "nmcli radio wifi on"))))

;; Function to turn on internet for 10 minutes
(define (internet-10-min)
  "Turn on the internet but only for 10 minutes to do a quick task."
  ;; First make sure internet is on
  (let ((status (system-output "nmcli -t -f WIFI radio")))
    (set! status (string-trim-both status))
    (when (string=? status "disabled")
      (system "nmcli radio wifi on")))

  ;; Block until the delay elapses, then turn it back off.
  (sleep 600)
  (system "nmcli radio wifi off"))

;; Command-line interface
(define (main args)
  (cond
   ;; If no arguments, just toggle the internet
   ((= (length args) 1)
    (toggle-internet))

   ;; If argument is "10min", turn on internet for 10 minutes
   ((and (= (length args) 2) (string=? (cadr args) "10min"))
    (internet-10-min))

   ;; If argument is a number, toggle after that many seconds
   ((and (= (length args) 2)
         (string->number (cadr args)))
    (let ((delay (string->number (cadr args))))
      ;; First make sure internet is on
      (let ((status (system-output "nmcli -t -f WIFI radio")))
        (set! status (string-trim-both status))
        (when (string=? status "disabled")
          (system "nmcli radio wifi on")))

      ;; Block until the delay elapses, then turn it back off.
      (sleep delay)
      (system "nmcli radio wifi off")))

   ;; Otherwise show usage
   (else
    (display "Usage: internet-toggle [10min | seconds]\n")
    (display "  No arguments: Toggle internet on/off\n")
    (display "  10min: Turn internet on for 10 minutes\n")
    (display "  seconds: Turn internet on for specified seconds\n"))))

(main (command-line))
