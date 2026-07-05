#!/usr/bin/env guile
!#

(use-modules (ice-9 ftw)
             (srfi srfi-13))

(define images-dir
  (string-append (getenv "HOME") "/Projects/images"))

(define (png? name)
  (string-suffix? ".png" (string-downcase name)))

(define (pick-png)
  (let* ((entries (or (scandir images-dir png?) '()))
         (n (length entries)))
    (and (positive? n)
         (string-append images-dir "/"
                        (list-ref entries
                                  (random n (random-state-from-platform)))))))

(define (main args)
  (let ((png (pick-png)))
    (if png
        (execlp "i3lock" "i3lock" "-n" "-i" png)
        (execlp "i3lock" "i3lock" "-n" "-c" "282828"))))

(main (command-line))
