#!/usr/bin/env guile
!#

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (srfi srfi-1)
             (fibers)
             (fibers channels)
             (fibers timers))

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

;; Function to toggle internet after a specified delay
(define (toggle-internet-after-delay delay)
  "Turn off the internet after a specified delay in seconds."
  (spawn-fiber
   (lambda ()
     (sleep delay)
     (system "nmcli radio wifi off"))))

;; Function to turn on internet for 10 minutes
(define (internet-10-min)
  "Turn on the internet but only for 10 minutes to do a quick task."
  ;; First make sure internet is on
  (let ((status (system-output "nmcli -t -f WIFI radio")))
    (set! status (string-trim-both status))
    (when (string=? status "disabled")
      (system "nmcli radio wifi on")))
  
  ;; Schedule turning it off
  (toggle-internet-after-delay 600))

;; Command-line interface - run within fibers
(define (main args)
  (run-fibers
   (lambda ()
     (cond
      ;; If no arguments, just toggle the internet
      ((= (length args) 1)
       (toggle-internet))
      
      ;; If argument is "10min", turn on internet for 10 minutes
      ((and (= (length args) 2) (string=? (cadr args) "10min"))
       (internet-10-min)
       ;; We need to keep the scheduler running until our task completes
       (sleep 601))
      
      ;; If argument is a number, toggle after that many seconds
      ((and (= (length args) 2) 
            (string->number (cadr args)))
       (let ((delay (string->number (cadr args))))
         ;; First make sure internet is on
         (let ((status (system-output "nmcli -t -f WIFI radio")))
           (set! status (string-trim-both status))
           (when (string=? status "disabled")
             (system "nmcli radio wifi on")))
         
         ;; Schedule turning it off and keep running
         (toggle-internet-after-delay delay)
         (sleep (+ delay 1))))
      
      ;; Otherwise show usage
      (else
       (display "Usage: internet-toggle [10min | seconds]\n")
       (display "  No arguments: Toggle internet on/off\n")
       (display "  10min: Turn internet on for 10 minutes\n")
       (display "  seconds: Turn internet on for specified seconds\n"))))
   #:drain? #t))  ;; This ensures all fibers complete before exiting

(main (command-line))
