;;; mail.scm --- Mailfence over IMAP: mbsync, notmuch, msmtp
;;;
;;; Mail lives in a local Maildir (~/Mail/mailfence) that mbsync mirrors
;;; from imap.mailfence.com every five minutes.  notmuch indexes it; its
;;; post-new hook runs scripts/mail-export.scm, which writes every new mail
;;; as a plain-text file to ~/Mail/text/<year>/ so agents and grep can read
;;; mail without a MIME parser.
;;;
;;; Directions:
;;;   - INBOX, Sent Items, Wichtig, Spam?: pull only.  Nothing local is ever
;;;     uploaded or deleted on the server.  Job mail often lands in spam,
;;;     which Mailfence empties after 30 days; the text export keeps it.
;;;   - Drafts: both directions.  scripts/mail-draft.scm drops a draft into
;;;     the local Drafts folder, mbsync uploads it, and it shows up in the
;;;     Mailfence web UI and apps for review and sending.
;;;
;;; Sending is msmtp only (Emacs message-mode).  The sync timer never sends.
;;;
;;; The password is read from ~/.local/share/mailfence/password (mode 600,
;;; outside the repo); it is never written into a config file.  One-time
;;; setup per device (paste the password, then Ctrl-D):
;;;   install -Dm600 /dev/stdin ~/.local/share/mailfence/password

(define-module (services mail)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages base)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages w3m)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:export (mail-services))

(define %imap-user "samuelschmidt")
(define %from-address (string-append "samuel" "@" "schmidt-contact.com"))
(define %mailfence-address (string-append "schmidt.samuel" "@" "mailfence.com"))
(define %ca-file "/etc/ssl/certs/ca-certificates.crt")

;; mbsync and msmtp both run this through /bin/sh, so ~ expands.
(define pass-command
  #~(string-append #$(file-append coreutils "/bin/cat")
                   " ~/.local/share/mailfence/password"))

;; mbsync >= 1.5 reads $XDG_CONFIG_HOME/isyncrc.
(define isyncrc
  (mixed-text-file
   "isyncrc"
   "IMAPAccount mailfence\n"
   "Host imap.mailfence.com\n"
   "Port 993\n"
   "TLSType IMAPS\n"
   "User " %imap-user "\n"
   "PassCmd \"" pass-command "\"\n"
   "CertificateFile " %ca-file "\n"
   ;; Mailfence answers slowly on big mails; 20 s (default) is too tight.
   "Timeout 60\n"
   "\n"
   "IMAPStore mailfence-remote\n"
   "Account mailfence\n"
   "\n"
   "MaildirStore mailfence-local\n"
   "Path ~/Mail/mailfence/\n"
   "Inbox ~/Mail/mailfence/INBOX\n"
   "SubFolders Verbatim\n"
   "\n"
   ;; Read-only mirror: never push, never expunge on the server.
   "Channel mailfence-read\n"
   "Far :mailfence-remote:\n"
   "Near :mailfence-local:\n"
   "Patterns INBOX \"Sent Items\" Wichtig \"Spam?\"\n"
   "Create Near\n"
   "Sync Pull\n"
   ;; Mailfence never finishes serving some very large mails (a 28 MB one
   ;; in Wichtig timed out even at 180 s); mbsync keeps a placeholder.
   "MaxSize 20m\n"
   "Expunge None\n"
   "SyncState *\n"
   "\n"
   ;; Drafts sync both ways so locally written drafts reach Mailfence.
   "Channel mailfence-drafts\n"
   "Far :mailfence-remote:Drafts\n"
   "Near :mailfence-local:Drafts\n"
   "Create Near\n"
   "Sync All\n"
   "Expunge Both\n"
   "SyncState *\n"
   "\n"
   "Group mailfence\n"
   "Channel mailfence-read\n"
   "Channel mailfence-drafts\n"))

(define msmtp-config
  (mixed-text-file
   "msmtp-config"
   "defaults\n"
   "auth on\n"
   "tls on\n"
   "tls_trust_file " %ca-file "\n"
   "logfile ~/.cache/msmtp.log\n"
   "\n"
   "account mailfence\n"
   "host smtp.mailfence.com\n"
   "port 465\n"
   "tls_starttls off\n"
   "from " %from-address "\n"
   "user " %imap-user "\n"
   "passwordeval \"" pass-command "\"\n"
   "\n"
   "account default : mailfence\n"))

;; A relative database.path is resolved against $HOME.
(define notmuch-config
  (plain-file
   "notmuch-config"
   (string-append
    "[database]\n"
    "path=Mail/mailfence\n"
    "\n"
    "[user]\n"
    "name=Samuel Levi Schmidt\n"
    "primary_email=" %from-address "\n"
    "other_email=" %mailfence-address ";\n"
    "\n"
    "[new]\n"
    "tags=new;\n"
    "ignore=.mbsyncstate;.uidvalidity;.mbsyncstate.journal;.mbsyncstate.new;\n"
    "\n"
    "[search]\n"
    "exclude_tags=deleted;spam;\n"
    "\n"
    "[maildir]\n"
    "synchronize_flags=true\n")))

;; The export script stays in the repo (like the agent launchers) so it can
;; be changed without a reconfigure; the hook only pins its tool paths.
(define notmuch-post-new-hook
  (program-file
   "notmuch-post-new"
   (with-extensions (list (@ (gnu packages guile) guile-json-4))
     #~(begin
         (setenv "PATH"
                 (string-append #$(file-append notmuch "/bin") ":"
                                #$(file-append w3m "/bin") ":"
                                (or (getenv "PATH") "")))
         (set-program-arguments (list "mail-export"))
         (load (string-append (getenv "HOME")
                              "/Projects/System/scripts/mail-export.scm"))))))

(define mail-sync-program
  (program-file
   "mail-sync"
   #~(begin
       ;; notmuch new still runs after a failed sync so local drafts are
       ;; indexed; the hook exports whatever did arrive.
       (system* #$(file-append isync "/bin/mbsync") "mailfence")
       (execl #$(file-append notmuch "/bin/notmuch") "notmuch" "new" "--quiet"))))

(define (mail-sync-timer _config)
  (list (shepherd-timer '(mail-sync)
                        "*/5 * * * *"
                        #~(#$mail-sync-program)
                        #:documentation "Sync Mailfence via mbsync, then notmuch new.")))

(define (mail-packages _config)
  (list isync notmuch msmtp w3m))

(define (mail-xdg-files _config)
  `(("isyncrc" ,isyncrc)
    ("msmtp/config" ,msmtp-config)
    ("notmuch/default/config" ,notmuch-config)
    ("notmuch/default/hooks/post-new" ,notmuch-post-new-hook)))

(define mail-service-type
  (service-type
   (name 'mailfence-mail)
   (extensions
    (list
     (service-extension home-profile-service-type mail-packages)
     (service-extension home-xdg-configuration-files-service-type mail-xdg-files)
     (service-extension home-shepherd-service-type mail-sync-timer)))
   (default-value #f)
   (description "Mirror Mailfence to a local Maildir and index it with notmuch.")))

(define (mail-services)
  (list (service mail-service-type)))
