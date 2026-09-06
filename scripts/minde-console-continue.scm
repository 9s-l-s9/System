#!/usr/bin/env -S guile -s
!#

(use-modules (ice-9 format))

;; One-shot continuation for 2026-09-02 01:20 UTC (03:20 CEST).
(define target-epoch 1788312000)
(define mindectl "/home/samuel/.guix-home/profile/bin/mindectl")
(define prompt
  "you hit your usage limits. try again. your subagents might have been interrupted as well. continue carefully. do not use full fable subagents and do not run multiple at the same time. avoid compiling multiple times and downloading additional software.")

(define (seconds-now)
  (car (gettimeofday)))

(define (wait-until epoch)
  (let loop ()
    (let ((remaining (- epoch (seconds-now))))
      (when (> remaining 0)
        (sleep (min remaining 60))
        (loop)))))

(define (group-two-konsole-expression action)
  (format
   #f
   "(begin (switch-to-group! \" II \") (let ((ids (filter (lambda (id) (string=? (window-app-id id) \"org.kde.konsole\")) (all-window-ids)))) (if (= (length ids) 1) (begin (focus-window-by-id! (car ids)) ~a #t) (error \"expected exactly one Konsole window in group II\" ids))))"
   action))

(define (minde-eval action)
  (let ((status
         (system* mindectl "eval" (group-two-konsole-expression action))))
    (unless (zero? status)
      (format (current-error-port)
              "minde-console-continue: Minde action failed: ~a~%" action)
      (exit 1))))

(wait-until target-epoch)
;; Ctrl+Shift+V is Konsole's text paste.  Plain Ctrl+V is captured by Codex as
;; image paste and therefore cannot be used here.
(minde-eval
 (format #f
         "(begin (wm-set-clipboard ~s) (wm-send-key 5 \"v\"))"
         prompt))
(sleep 4)
(minde-eval "(wm-send-key 0 \"Return\")")
(sleep 15)
(minde-eval
 "(wm-spawn \"grim /home/samuel/Projects/System/minde-console-continue-result.png\")")
(system* "/home/samuel/.guix-home/profile/bin/minde-msg"
         "-t" "5000" "Scheduled group-II agent continuation submitted.")
