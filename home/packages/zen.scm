(define-module (packages zen)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((zen-browser-bin) #:prefix binary-guix:)
  #:export (zen-browser-bin))

;; Keep the upstream browser package's files and dependencies, but make its
;; public launcher select the profile marked default in profiles.ini.  In
;; particular, this makes launches from both a shell and a desktop entry
;; behave identically.
;; Select the binary-guix package explicitly.  The saayix package can lag
;; behind and forces MOZ_ALLOW_DOWNGRADE=1: Firefox 152 cannot initialize
;; storage containing Cache API databases written by Firefox 155.
(define upstream-zen-browser-bin binary-guix:zen-browser-bin)

(define zen-launcher
  (program-file
   "zen-launcher"
   #~(begin
       (use-modules (ice-9 rdelim)
                    (ice-9 format)
                    (srfi srfi-1)
                    (srfi srfi-13))

       (define zen #$(file-append upstream-zen-browser-bin "/bin/zen"))

       (define (profile-option? argument)
         (let ((argument (string-downcase argument)))
           (or (member argument '("--profile" "-profile" "-p"
                                  "--profilemanager" "-profilemanager"))
               (string-prefix? "--profile=" argument))))

       ;; Return the directory of the [ProfileN] section carrying Default=1
       ;; in ~/.zen/profiles.ini, or #f.  The profile's random directory
       ;; name differs per machine, so it must not be pinned in this file.
       (define (default-profile-directory zen-dir)
         (let ((ini (string-append zen-dir "/profiles.ini")))
           (and (file-exists? ini)
                (call-with-input-file ini
                  (lambda (port)
                    (let loop ((line (read-line port))
                               (in-profile? #f) (path #f) (relative? #t)
                               (default? #f) (result #f))
                      (define (finish)
                        (if (and in-profile? default? path)
                            (if relative?
                                (string-append zen-dir "/" path)
                                path)
                            result))
                      (if (eof-object? line)
                          (finish)
                          (let ((line (string-trim-both line)))
                            (cond
                             ((string-prefix? "[" line)
                              (loop (read-line port)
                                    (string-prefix? "[Profile" line)
                                    #f #t #f (finish)))
                             ((string-prefix? "Path=" line)
                              (loop (read-line port) in-profile?
                                    (substring line 5) relative? default? result))
                             ((string=? line "IsRelative=0")
                              (loop (read-line port) in-profile?
                                    path #f default? result))
                             ((string=? line "Default=1")
                              (loop (read-line port) in-profile?
                                    path relative? #t result))
                             (else
                              (loop (read-line port) in-profile?
                                    path relative? default? result)))))))))))

       (define arguments (cdr (command-line)))
       ;; Keep Firefox's profile downgrade protection, even if this variable
       ;; was inherited from a shell or an older browser launcher.
       (unsetenv "MOZ_ALLOW_DOWNGRADE")
       (define home (getenv "HOME"))
       (define profile
         (and home
              (not (any profile-option? arguments))
              (let ((directory (false-if-exception
                                (default-profile-directory
                                  (string-append home "/.zen")))))
                (and directory
                     (false-if-exception (file-is-directory? directory))
                     directory))))
       (if profile
           (apply execl zen (append (list zen "--profile" profile) arguments))
           ;; Never refuse to start: let Zen choose its own profile.
           (apply execl zen (cons zen arguments))))))

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
