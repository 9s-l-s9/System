(define-module (services emacs)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages)
  #:use-module (guix gexp)
  #:export (emacs-daemon-service))

;; Run Emacs as a user daemon so frames open instantly via `emacsclient -c`.
;; init.el no longer calls `server-start'; this service is the only server.
(define (emacs-daemon-service)
  (simple-service
   'emacs-daemon
   home-shepherd-service-type
   (list (shepherd-service
          (documentation "Emacs daemon; connect with emacsclient -c.")
          (provision '(emacs-daemon))
          (start #~(make-forkexec-constructor
                    (list #$(file-append
                             (specification->package "emacs-next")
                             "/bin/emacs")
                          "--fg-daemon")))
          (stop #~(make-kill-destructor))
          (respawn? #t)))))
