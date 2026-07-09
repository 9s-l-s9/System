#!/usr/bin/env guile
!#

(use-modules (ice-9 ftw)
             (ice-9 binary-ports)
             (srfi srfi-13))

(define images-dir
  (string-append (getenv "HOME") "/Projects/images"))

(define (png? name)
  (string-suffix? ".png" (string-downcase name)))

;; Many files in images-dir are WebP/JPEG despite their .png extension;
;; i3lock only decodes real PNGs, so check the magic bytes, not the name.
(define %png-magic #vu8(#x89 #x50 #x4e #x47 #x0d #x0a #x1a #x0a))

(define (real-png? path)
  (catch #t
    (lambda ()
      (call-with-input-file path
        (lambda (port)
          (equal? (get-bytevector-n port 8) %png-magic))
        #:binary #t))
    (lambda _ #f)))

(define (pick-png)
  (let* ((entries (filter (lambda (name)
                            (real-png? (string-append images-dir "/" name)))
                          (or (scandir images-dir png?) '())))
         (n (length entries)))
    (and (positive? n)
         (string-append images-dir "/"
                        (list-ref entries
                                  (random n (random-state-from-platform)))))))

(define (main args)
  (let ((png (pick-png)))
    (if png
        ;; -c is the fallback if the image still fails to load: a dark screen
        ;; is recognizably a locker, an i3lock-default white one is not.
        (execlp "i3lock" "i3lock" "-n" "-c" "282828" "-i" png)
        (execlp "i3lock" "i3lock" "-n" "-c" "282828"))))

(main (command-line))
