;;; calendar.scm --- Mailfence calendar over CalDAV: vdirsyncer, notyet
;;;
;;; The Mailfence calendar is mirrored to a vdir (~/Calendar/mailfence/events,
;;; one .ics file per event) by vdirsyncer, in both directions, every five
;;; minutes.  notyet (~/Projects/notyet, linked live into ~/.local/bin like
;;; the agent launchers) searches and edits that directory by search terms
;;; and syncs right after each change; after every sync it rewrites the
;;; plain-text mirror ~/Calendar/text/ for agents and grep.
;;;
;;; What Mailfence does with CalDAV (tested 2026-11-05):
;;;   - VALARM ACTION:EMAIL becomes an e-mail reminder (it arrives in INBOX).
;;;   - CATEGORIES become Mailfence tags.
;;;   - COLOR is ignored and colours are never exported, but an event keeps
;;;     a colour set in the web UI when it is rewritten over CalDAV.  notyet's
;;;     colour pool (placeholders "notyet-pool: TYPE" on 2000-01-01) uses this.
;;;   - Only one personal calendar; more exist only as group calendars.
;;;
;;; The password is the Mailfence one from ~/.local/share/mailfence/password,
;;; the login and addresses come from identity.scm there (lib mail-identity)
;;; (see mail.scm); neither is written into this repository.

(define-module (services calendar)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages dav)
  #:use-module (gnu packages guile)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:use-module (lib mail-identity)
  #:export (calendar-services))

(define %caldav-user (mail-identity 'user))
(define %me (mail-identity 'address))
(define %mailfence-address (mail-identity 'mailfence-address))
;; New event UIDs end in the domain of the From address.
(define %uid-domain (substring %me (+ 1 (string-index %me #\@))))

;; $XDG_CONFIG_HOME/vdirsyncer/config.  The local side is a plain vdir; the
;; collection is named explicitly so `discover' never has to ask.
(define vdirsyncer-config
  (mixed-text-file
   "vdirsyncer-config"
   "[general]\n"
   "status_path = \"~/.local/share/vdirsyncer/status/\"\n"
   "\n"
   "[pair mailfence]\n"
   "a = \"mailfence_local\"\n"
   "b = \"mailfence_remote\"\n"
   "collections = [\"events\"]\n"
   "\n"
   "[storage mailfence_local]\n"
   "type = \"filesystem\"\n"
   "path = \"~/Calendar/mailfence/\"\n"
   "fileext = \".ics\"\n"
   "\n"
   "[storage mailfence_remote]\n"
   "type = \"caldav\"\n"
   "url = \"https://mailfence.com/dav/principals/accounts/" %caldav-user "/\"\n"
   "username = \"" %caldav-user "\"\n"
   "password.fetch = [\"command\", \"" bash-minimal "/bin/sh\", \"-c\", \""
   coreutils "/bin/cat ~/.local/share/mailfence/password\"]\n"))

;; $XDG_CONFIG_HOME/notyet/config.scm.  Types follow what this calendar is
;; used for (applications, thesis); colours are the ones to give each type's
;; pool placeholders in the Mailfence web UI.
(define notyet-config
  (plain-file
   "notyet-config.scm"
   (object->string
    `((calendars ("mailfence" . "~/Calendar/mailfence/events"))
      (default-calendar . "mailfence")
      (timezone . "Europe/Berlin")
      (me ,%me ,%mailfence-address)
      (uid-domain . ,%uid-domain)
      (sync-command "vdirsyncer" "sync")
      (export-dir . "~/Calendar/text")
      (reminder-action . "EMAIL")
      (types
       ("Gespräch" (color . "blue") (duration . "1h") (reminder . "1d")
        (about . "Interview, call, Kennenlernen; title \"Firma: Art (Person)\""))
       ("Frist" (color . "red") (all-day . #t) (reminder . "2d")
        (about . "Deadline, online test, submission"))
       ("Fokus" (color . "green") (duration . "2h")
        (about . "Deep work: applications, thesis, interview preparation"))
       ("Uni" (color . "purple") (duration . "1h") (reminder . "1h")
        (about . "Thesis, supervisor, presentation"))
       ("Nachhaken" (color . "orange") (duration . "15m") (reminder . "start")
        (about . "Follow-up: e-mail reminder at the time; note the mail's Message-ID"))
       ("Privat" (color . "pink") (about . "Private")))))))

(define calendar-sync-program
  (program-file
   "calendar-sync"
   (with-imported-modules '((guix build utils))
     #~(begin
       (use-modules ((guix build utils) #:select (mkdir-p)))
       (let ((home (getenv "HOME")))
         (setenv "PATH" (string-append #$(file-append vdirsyncer "/bin") ":"
                                       #$(file-append guile-3.0 "/bin") ":"
                                       (or (getenv "PATH") "")))
         (mkdir-p (string-append home "/Calendar/mailfence/events"))
         ;; discover records the pair after a config change; it never prompts
         ;; because the collection is named and the directory exists.
         (system* "vdirsyncer" "discover")
         (system* "vdirsyncer" "sync")
         (let ((notyet (string-append home "/Projects/notyet/bin/notyet")))
           (when (file-exists? notyet)
             ;; Unfinished to-dos and missed Fokus blocks move to today;
             ;; carry syncs again only on a change.
             (system* notyet "carry")
             ;; Export even after a sync failure; local state is valid.
             (execl notyet "notyet" "export"))))))))

(define (calendar-sync-timer _config)
  (list (shepherd-timer '(calendar-sync)
                        "*/5 * * * *"
                        #~(#$calendar-sync-program)
                        #:documentation
                        "Sync the Mailfence calendar via vdirsyncer, carry open to-dos, then notyet export.")))

;; Like the agent launchers: link the live checkout so edits to notyet take
;; effect without a reconfigure.
(define notyet-activation
  #~(begin
     (use-modules ((guix build utils) #:select (mkdir-p)))
     (let* ((home (getenv "HOME"))
           (target (string-append home "/Projects/notyet/bin/notyet"))
           (link (string-append home "/.local/bin/notyet")))
      (if (not (file-exists? target))
          (format (current-error-port) "calendar: ~a missing; notyet not linked~%" target)
          (begin
            (mkdir-p (dirname link))
            (cond
             ((equal? (false-if-exception (readlink link)) target) #t)
             ((false-if-exception (readlink link))
              (delete-file link) (symlink target link))
             ((file-exists? link)
              (format (current-error-port)
                      "calendar: refusing to replace non-symlink ~a~%" link))
             (else (symlink target link))))))))

(define (calendar-packages _config)
  (list vdirsyncer))

(define (calendar-xdg-files _config)
  `(("vdirsyncer/config" ,vdirsyncer-config)
    ("notyet/config.scm" ,notyet-config)))

(define calendar-service-type
  (service-type
   (name 'mailfence-calendar)
   (extensions
    (list
     (service-extension home-profile-service-type calendar-packages)
     (service-extension home-xdg-configuration-files-service-type calendar-xdg-files)
     (service-extension home-shepherd-service-type calendar-sync-timer)
     (service-extension home-activation-service-type (const notyet-activation))))
   (default-value #f)
   (description "Mirror the Mailfence calendar with vdirsyncer; notyet on top.")))

(define (calendar-services)
  (list (service calendar-service-type)))
