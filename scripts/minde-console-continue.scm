#!/usr/bin/env -S guile -s
!#
;;; -*- coding: utf-8 -*-
;; One-shot agent input for 2026-10-14 03:57:25 CEST.
;; --check only validates targets; --send-now pastes and submits immediately.

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 regex)
             (ice-9 textual-ports)
             (srfi srfi-13))

(define target-epoch 1791943045)
(define prompt "continue with your original idea or reflect on what else to do to improve the overall goal and work on that arbeite unabhängig und stelle erstmal keine weiteren rückfragen")
(define minde-session "440-6accf288-1aa6e")
(define bus-owner ":1.27")
(define targets '((20 3 1 2176) (21 4 2 26795)))
(define mindectl "/home/samuel/.guix-home/profile/bin/mindectl")
(define dbus-send "/home/samuel/.guix-home/profile/bin/dbus-send")

(define (log-message message)
  (format #t "~a pid=~a ~a~%" (strftime "%Y-%m-%d %H:%M:%S %Z" (localtime (current-time))) (getpid) message)
  (force-output))

(define (capture program . arguments)
  (let* ((pipe (apply open-pipe* OPEN_READ program arguments))
         (output (begin (set-port-encoding! pipe "UTF-8")
                        (get-string-all pipe)))
         (status (close-pipe pipe)))
    (unless (zero? status)
      (error "Command failed" program arguments output))
    output))

(define (bus-call path method)
  (capture dbus-send "--session" "--print-reply" "--reply-timeout=5000"
           (string-append "--dest=" bus-owner) path
           (string-append "org.kde.konsole." method)))

(define (bus-integer path method)
  (let ((match (string-match "int32 ([0-9]+)" (bus-call path method))))
    (unless match (error "Unexpected D-Bus reply" path method))
    (string->number (match:substring match 1))))

(define (without-whitespace text)
  ;; Konsole may insert line breaks when the longer prompt wraps.
  (string-filter (lambda (character) (not (char-whitespace? character))) text))

(define (check-target target)
  (let ((window (list-ref target 1))
        (session (list-ref target 2))
        (process (list-ref target 3)))
    (unless (= session (bus-integer (format #f "/Windows/~a" window) "Window.currentSession"))
      (error "Konsole window changed sessions" target))
    (unless (= process (bus-integer (format #f "/Sessions/~a" session) "Session.foregroundProcessId"))
      (error "Original agent process is no longer in the foreground" target))))

(define (input-action target action)
  (check-target target)
  (let ((expression
         (format #f
                 "(begin (unless (string=? (assq-ref (desktop-snapshot) 'session) ~s) (error \"minde session changed\")) (unless (string=? (window-app-id ~a) \"org.kde.konsole\") (error \"target window changed\")) (let ((receipt (perform-action! 'focus-window! '((window . ~a))))) (unless (memq (assq-ref receipt 'status) '(applied unchanged)) (error \"focus failed\" receipt))) (unless (equal? (assq-ref (desktop-snapshot) 'focused-window) ~a) (error \"target is not focused\")) ~a #t)"
                 minde-session (car target) (car target) (car target) action)))
    (capture mindectl "eval" expression)))

(define (pending-prompt-visible? target)
  (let* ((text (bus-call (format #f "/Sessions/~a" (list-ref target 2))
                         "Session.getAllDisplayedText"))
         (index (string-rindex text #\❯)))
    (and index
         (string-contains (without-whitespace (string-drop text index))
                          (without-whitespace prompt)))))

(define (wait-for-prompt target)
  (let loop ((remaining 15))
    (cond
     ((pending-prompt-visible? target) #t)
     ((zero? remaining)
      (error "Pasted prompt was not visible; Enter was withheld" target))
     (else (sleep 2) (loop (- remaining 1))))))

(define (submit-visible-target target)
  (catch #t
    (lambda ()
      (wait-for-prompt target)
      (input-action target "(wm-send-key 0 \"Return\")")
      (log-message (format #f "SUBMITTED window=~a session=~a" (car target) (list-ref target 2))))
    (lambda (key . arguments)
      (log-message (format #f "FAILED window=~a ~s ~s" (car target) key arguments)))))

(define (send-target target)
  (catch #t
    (lambda ()
      ;; Clear the agent's current draft so the submitted input is exact.
      (input-action target "(wm-send-key 4 \"u\")")
      (sleep 1)
      (input-action target (format #f "(begin (wm-set-clipboard ~s) (wm-send-key 5 \"v\"))" prompt))
      (sleep 2)
      (wait-for-prompt target)
      (input-action target "(wm-send-key 0 \"Return\")")
      (log-message (format #f "SUBMITTED window=~a session=~a" (car target) (list-ref target 2))))
    (lambda (key . arguments)
      (log-message (format #f "FAILED window=~a ~s ~s" (car target) key arguments)))))

(define (wait-until-target)
  (let loop ()
    (let ((remaining (- target-epoch (current-time))))
      (when (> remaining 0)
        (sleep (min remaining 60))
        (loop)))))

(for-each check-target targets)
(cond
 ((member "--check" (command-line))
  (log-message (format #f "CHECKED targets=~s due=~a" targets target-epoch)))
 ((member "--send-now" (command-line))
  (log-message "TEST STARTED")
  (for-each send-target targets)
  (log-message "TEST FINISHED"))
 ((member "--submit-visible" (command-line))
  (log-message "SUBMIT VISIBLE STARTED")
  (for-each submit-visible-target targets)
  (log-message "SUBMIT VISIBLE FINISHED"))
 (else
  (log-message (format #f "ARMED targets=~s due=~a" targets target-epoch))
  (wait-until-target)
  (for-each send-target targets)
  (log-message "FINISHED")))
