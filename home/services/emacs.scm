(define-module (services emacs)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module ((gnu services shepherd) #:select (%default-modules))
  #:use-module (gnu packages)
  #:use-module (guix gexp)
  #:export (emacs-daemon-service))

;; Run Emacs as a user daemon so frames open instantly via `emacsclient -c`.
;; init.el no longer calls `server-start'; this service is the only server.
;;
;; Shepherd starts before the compositor, so its environment has no
;; WAYLAND_DISPLAY/DISPLAY; without them eat shells, dired and browse-url
;; cannot open GUI programs ("no DISPLAY").  minde records both in
;; $XDG_RUNTIME_DIR/graphical-session.env at startup and pushes them into
;; the running daemon (see minde.scm); a later restart or respawn reads the
;; file here.
(define (emacs-daemon-service)
  (simple-service
   'emacs-daemon
   home-shepherd-service-type
   (list (shepherd-service
          (documentation "Emacs daemon; connect with emacsclient -c.")
          (provision '(emacs-daemon))
          (modules `((ice-9 rdelim) ,@%default-modules))
          (start #~(lambda args
                     (let* ((file (string-append
                                   (or (getenv "XDG_RUNTIME_DIR") "/tmp")
                                   "/graphical-session.env"))
                            (session
                             (if (file-exists? file)
                                 (call-with-input-file file
                                   (lambda (port)
                                     (let loop ((lines '()))
                                       (let ((line (read-line port)))
                                         (cond
                                          ((eof-object? line) (reverse lines))
                                          ((string-index line #\=)
                                           (loop (cons line lines)))
                                          (else (loop lines)))))))
                                 '())))
                       (apply (make-forkexec-constructor
                               (list #$(file-append
                                        (specification->package "emacs-next-pgtk")
                                        "/bin/emacs")
                                     "--fg-daemon")
                               #:environment-variables
                               (append session (default-environment-variables)))
                              args))))
          (stop #~(make-kill-destructor))
          (respawn? #t)))))
