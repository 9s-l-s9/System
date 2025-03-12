(define-module (services lem)
  #:use-module (gnu)
  #:use-module (lem-home-service)
  #:use-module (gnu packages text-editors)
  #:export (lem-service))

(define (lem-service)
  (service home-lem-service-type
           (home-lem-configuration
            (package lem)
            ;; Add any additional modules if needed
            ;; (lem-modules (list some-lem-module))
            (config
             (list
              #~"(in-package :lem-user)"
              #~"(load-theme \"black-metal-bathory\")"
              #~"(defvar *sls-main-keymap*"
              #~"  (make-keymap :name '*sls-main-keymap*)"
              #~"  \"Private keymap.\")"
              #~"(define-key *sls-main-keymap* \"b\" 'describe-bindings)"
              #~"(define-key *sls-main-keymap* \"f\" 'find-file)"
              #~"(define-key *sls-main-keymap* \"s\" 'save-current-buffer)"
              #~"(define-key *sls-main-keymap* \"q\" 'execute-command)"
              #~"(define-key *sls-main-keymap* \"d\" 'delete-active-window)"
              #~"(define-key *sls-main-keymap* \"t\" 'terminal)"
              #~"(define-key *sls-main-keymap* \"o\" 'lem-core/commands/file:find-file-recursively)"
              #~"(define-key *sls-main-keymap* \"c\" 'copy-region-to-clipboard)"
              #~"(define-key *sls-main-keymap* \"Return\" 'terminal)"
              #~"(define-key *global-keymap* \"F12\" *sls-main-keymap*)")))))
