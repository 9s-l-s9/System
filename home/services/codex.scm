(define-module (services codex)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (codex-service))

;; Codex writes model choices, project trust and other settings back to
;; ~/.codex/config.toml. A home-dotfiles store symlink makes those saves fail.
;; Keep the template outside home/files and seed a mutable file only once.
(define codex-config-template
  (local-file "codex-config.toml"))

(define codex-config-activation
  #~(begin
      (use-modules (srfi srfi-13))

      (let* ((directory (string-append (getenv "HOME") "/.codex"))
             (config (string-append directory "/config.toml"))
             (target (false-if-exception (readlink config))))
        (define (install-config source)
          ;; Prepare the writable copy before atomically replacing the old
          ;; link, so a failed copy leaves the original settings intact.
          (let* ((port (mkstemp! (string-append config ".XXXXXX")))
                 (temporary (port-filename port)))
            (close-port port)
            (dynamic-wind
              (lambda () #t)
              (lambda ()
                (copy-file source temporary)
                (chmod temporary #o600)
                (rename-file temporary config))
              (lambda ()
                (when (file-exists? temporary)
                  (delete-file temporary))))))

        (unless (file-exists? directory)
          (mkdir directory #o700))
        (cond
         ;; Migrate the old dotfiles link without losing its current values.
         ((and target (string-prefix? "/gnu/store/" target))
          (install-config (if (file-exists? config)
                              config
                              #$codex-config-template)))
         ;; Preserve existing user files and custom symlinks on reconfigure.
         ((and (not target) (not (file-exists? config)))
          (install-config #$codex-config-template))))))

(define codex-service-type
  (service-type
   (name 'mutable-codex)
   (extensions
    (list
     (service-extension home-activation-service-type
                        (lambda (_) codex-config-activation))))
   (default-value #f)
   (description "Seed writable Codex settings and migrate store symlinks.")))

(define (codex-service)
  (service codex-service-type))
