;;; bigme.scm --- Sync PDFs to the Bigme inkNote Color+ e-ink tablet over adb
;;;
;;; The tablet keeps wireless debugging on in the home WLAN (KeepADB on the
;;; device) and adb finds it via mDNS.  Every ten minutes the timer runs
;;; ~/.local/share/bigme/bigme-sync.py: new or changed PDFs go to the
;;; tablet as original plus a screen-sized version (bigme-prep.py), and the
;;; KOReader sidecars with highlights come back to
;;; ~/.local/share/bigme/pulled/.  Reviewed flashcards of the learning
;;; papers become page-turn decks; cards bookmarked there are collected in
;;; ~/.local/share/bigme/anki/ for Anki.  When the tablet is not reachable the
;;; script exits at once. The legacy Python tools are local, unversioned
;;; files; restore them from the working device before enabling this workflow
;;; on another machine. Without them the timer does nothing. Future versions
;;; belong under home/files/ (outside the scripts/ Guile-only rule).

(define-module (services bigme)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages python)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix profiles)
  #:use-module (guix utils)
  #:use-module (android-platform-tools-bin)
  #:use-module (typst-bin)
  #:export (bigme-services))

;; One profile, so PyMuPDF finds its propagated inputs (the mupdf module).
(define bigme-python
  (profile (content (packages->manifest (list python python-pymupdf)))))

(define bigme-sync-program
  (program-file
   "bigme-sync"
   #~(begin
       (unless (file-exists?
                (string-append (getenv "HOME") "/.local/share/bigme/bigme-sync.py"))
         (exit 0))
       (setenv "GUIX_PYTHONPATH"
               (string-append #$bigme-python "/lib/python"
                              #$(version-major+minor (package-version python))
                              "/site-packages"))
       (setenv "BIGME_ADB" #$(file-append android-platform-tools-bin "/bin/adb"))
       ;; typst builds the flashcard decks (cards.typ)
       (setenv "PATH" (string-append #$typst-bin "/bin:" (or (getenv "PATH") "")))
       (execl #$(file-append bigme-python "/bin/python3") "python3"
              (string-append (getenv "HOME") "/.local/share/bigme/bigme-sync.py")))))

(define (bigme-sync-timer _config)
  (list (shepherd-timer '(bigme-sync)
                        "*/10 * * * *"
                        #~(#$bigme-sync-program)
                        #:documentation "Sync PDFs to the Bigme tablet when it is in the WLAN.")))

(define bigme-service-type
  (service-type
   (name 'bigme)
   (extensions
    (list (service-extension home-shepherd-service-type bigme-sync-timer)))
   (default-value #f)
   (description "Sync PDFs to the Bigme e-ink tablet over adb.")))

(define (bigme-services)
  (list (service bigme-service-type)))
