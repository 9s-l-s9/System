(define-module (packages zen)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((saayix packages binaries) #:prefix saayix:)
  #:export (zen-browser-bin))

;; Keep the upstream browser package's files and dependencies, but make its
;; public launcher select the profile used by this installation.  In
;; particular, this makes launches from both a shell and a desktop entry
;; behave identically.
(define upstream-zen-browser-bin saayix:zen-browser-bin)

(define zen-launcher
  (program-file
   "zen-launcher"
   #~(begin
       (use-modules (ice-9 ftw)
                    (ice-9 format)
                    (srfi srfi-1)
                    (srfi srfi-13))

       (define zen #$(file-append upstream-zen-browser-bin "/bin/zen"))

       (define (profile-option? argument)
         (let ((argument (string-downcase argument)))
           (or (member argument '("--profile" "-profile" "-p"
                                  "--profilemanager" "-profilemanager"))
               (string-prefix? "--profile=" argument))))

       (define arguments (cdr (command-line)))
       (if (any profile-option? arguments)
           (apply execl zen (cons zen arguments))
           (let ((home (getenv "HOME")))
             (if (and home
                      (false-if-exception
                       (file-is-directory?
                        (string-append home "/.zen/otgk42t9.default"))))
                 (apply execl zen
                        (append (list zen "--profile"
                                      (string-append home "/.zen/otgk42t9.default"))
                                arguments))
                 (begin
                   (format (current-error-port)
                           "zen: default profile directory is missing: ~a~%"
                           (if home
                               (string-append home "/.zen/otgk42t9.default")
                               "$HOME/.zen/otgk42t9.default"))
                   (exit 1))))))))

(define zen-browser-bin
  (package
    (inherit upstream-zen-browser-bin)
    (name "zen-browser-bin")
    (source #f)
    (native-inputs '())
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils) (guix build union))
      #:builder
      #~(begin
          (use-modules (guix build utils) (guix build union))
          (union-build #$output
                       (list #$(this-package-input "zen-browser-bin"))
                       #:create-all-directories? #t)
          (delete-file (string-append #$output "/bin/zen"))
          (symlink #$zen-launcher (string-append #$output "/bin/zen"))
          ;; Retain the upstream desktop entry, changing only its executable
          ;; token so action entries and MIME associations remain intact.
          (let ((desktop (string-append #$output "/share/applications/zen.desktop"))
                (source (string-append #$(this-package-input "zen-browser-bin")
                                       "/share/applications/zen.desktop")))
            (delete-file desktop)
            (copy-file source desktop)
          (substitute*
              desktop
            (("^Exec=[^[:space:]]+(.*)$" _ arguments)
             (string-append "Exec=" #$output "/bin/zen" arguments)))))
          ))
    (inputs (list upstream-zen-browser-bin))))
