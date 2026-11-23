#!/usr/bin/env -S guix repl -q --
!#
;;; Fetch, authenticate, and import GitHub-built Minde. No global key trust.
(add-to-load-path (dirname (current-filename)))
(use-modules (lib minde-binary)
             (ice-9 match)
             (ice-9 format)
             (ice-9 popen)
             (ice-9 textual-ports)
             (srfi srfi-1)
             (srfi srfi-13)
             (guix build utils)
             ((guix build syscalls) #:select (mkdtemp!))
             (guix store)
             (guix pki)
             (guix nar)
             (gcrypt pk-crypto))

(define self (canonicalize-path (current-filename)))
(define system-directory (dirname (dirname self)))

(define (temporary-directory)
  (mkdtemp! "/tmp/minde-binary.XXXXXX"))

(define (fetch-release commit)
  (unless (full-commit? commit) (error "provide a full 40-character commit"))
  (let ((directory (temporary-directory)))
    (set-download-trust! (string-append directory "/trust"))
    ;; Public release URLs avoid requiring a GitHub login on each PC.
    ;; Authentication comes from the attestation and signatures below.
    (for-each
     (lambda (name)
       (run! "curl" "--fail" "--silent" "--show-error" "--location"
             "--proto" "=https" "--proto-redir" "=https" "--retry" "3"
             "--cacert" (getenv "SSL_CERT_FILE")
             "--output" (string-append directory "/" name)
             (string-append "https://github.com/" minde-repository
                            "/releases/download/guix-" commit "/" name)))
     release-files)
    (verify-release! directory commit)
    directory))

(define (restore-release directory)
  (unless (zero? (geteuid)) (error "the store import requires root"))
  (when (string=? (readlink "/proc/self/ns/mnt")
                  (readlink (format #f "/proc/~a/ns/mnt" (getppid))))
    (error "the import must run in its own mount namespace"))
  (unless (zero? (stat:uid (stat "/gnu/store")))
    (error "this importer requires a root-owned Guix store"))
  ;; This process is started with an isolated GUIX_CONFIGURATION_DIRECTORY.
  ;; It must never use or change /etc/guix/acl.
  (unless (and (getenv "GUIX_CONFIGURATION_DIRECTORY")
               (string-prefix? "/tmp/minde-binary."
                               (getenv "GUIX_CONFIGURATION_DIRECTORY")))
    (error "missing temporary import ACL"))
  ;; Guix exposes the store read-only outside the daemon. Make a writable
  ;; bind mount only inside this process's private namespace, leaving the
  ;; system's mount and daemon configuration untouched.
  (run! "mount" "--bind" "/gnu/store" "/gnu/store")
  (run! "mount" "-o" "remount,bind,rw" "/gnu/store")
  (let* ((metadata (read-metadata (string-append directory "/binary.scm")))
         (closure (read-closure (string-append directory "/closure.txt") metadata))
         (commit (assoc-ref metadata 'commit))
         (root-directory "/var/guix/gcroots/minde-binary"))
    (with-store store
      ;; Protect every item throughout the direct import, including items
      ;; that become valid before the final Minde output has been restored.
      (for-each (lambda (path) (add-temp-root store path)) closure)
      (let* ((port (open-pipe* OPEN_READ "xz" "--decompress" "--stdout"
                               (string-append directory "/minde-x86_64-linux.nar.xz")))
             ;; Guix's own importer verifies each NAR signature against the
             ;; temporary ACL. Signature checking is never disabled.
             (restored (restore-file-set port)))
        (unless (zero? (close-pipe port)) (error "archive decompression failed"))
        (unless (lset= string=? restored closure)
          (error "imported items differ from the attested closure")))
      (unless (every (lambda (path) (valid-path? store path)) closure)
        (error "incomplete imported closure"))
      (mkdir-p root-directory)
      (for-each
       (lambda (name)
         (let* ((path (assoc-ref metadata name))
                (root (string-append root-directory "/" commit "-" (symbol->string name))))
           (if (file-exists? root)
               (unless (string=? (readlink root) path)
                 (error "existing GC root points at a different build" root))
               (symlink path root))))
       '(minde xwayland))
      ;; Keep the new build and the previous lock until reconfiguration.
      ;; Older generations retain their own store references.
      (let ((lock (string-append system-directory "/minde-binary.lock.scm")))
        (prune-binary-roots!
         root-directory
         (cons commit
               (if (file-exists? lock)
                   (list (assoc-ref (read-metadata lock) 'commit))
                   '())))))))

(define (import-release directory commit)
  (unless (zero? (geteuid)) (error "the store import requires root"))
  (let ((private (temporary-directory)))
    (dynamic-wind
      (lambda () #t)
      (lambda ()
        ;; Copy first, then verify again as root. This prevents replacement of
        ;; a user-owned download between signature verification and import.
        (for-each
         (lambda (name)
           (copy-file (string-append directory "/" name)
                      (string-append private "/" name))) release-files)
        (set-download-trust! (string-append private "/trust"))
        (verify-release! private commit)
        (let* ((config (string-append private "/guix"))
               (key (call-with-input-file (string-append private "/signing-key.pub")
                      (lambda (port) (string->canonical-sexp (get-string-all port))))))
          (mkdir config #o700)
          (call-with-output-file (string-append config "/acl")
            (lambda (port) (write-acl (public-keys->acl (list key)) port)))
          (run! "unshare" "--mount" "--propagation" "private"
                "env" (string-append "GUIX_CONFIGURATION_DIRECTORY=" config)
                "guix" "repl" "-q" "--" self "--restore" private)))
      (lambda () (delete-file-recursively private)))))

(define (install-release commit)
  (unless (string=? (utsname:machine (uname)) "x86_64")
    (error "this Minde binary is for x86_64-linux"))
  (let ((directory (fetch-release commit)))
    (dynamic-wind
      (lambda () #t)
      (lambda ()
        (let ((lock (string-append system-directory "/minde-binary.lock.scm")))
          (when (file-exists? lock)
            (let ((pinned (read-metadata lock)))
              (when (and (string=? (assoc-ref pinned 'commit) commit)
                         (not (equal? pinned
                                      (read-metadata (string-append directory "/binary.scm")))))
                (error "published build changed for an already pinned commit")))))
        ;; sudo needs the caller's installed gh and guix. Both archives and
        ;; metadata are authenticated again by the privileged process.
        (run! "sudo" "env" (string-append "PATH=" (getenv "PATH"))
              "guix" "repl" "-q" "--" self "--import" directory commit)
        (let* ((metadata (read-metadata (string-append directory "/binary.scm")))
               (target (string-append system-directory "/minde-binary.lock.scm"))
               (temporary (string-append target ".new")))
          (with-store store
            (unless (every (lambda (name) (valid-path? store (assoc-ref metadata name)))
                           '(minde xwayland))
              (error "import did not register the requested runtime")))
          (let* ((port (open-pipe* OPEN_READ
                                  (string-append (assoc-ref metadata 'minde) "/bin/minde")
                                  "--version"))
                 (version (string-trim-right (get-string-all port))))
            (unless (and (zero? (close-pipe port))
                         (string=? version (format #f "minde ~a (~a)"
                                                   (assoc-ref metadata 'version) commit)))
              (error "imported Minde reports a different version or revision" version)))
          (copy-file (string-append directory "/binary.scm") temporary)
          (rename-file temporary target)
          (format #t "Minde binary imported and pinned to ~a.~%" commit)
          (format #t "Run make reconfigure-system and make reconfigure-home to select it.~%")
          (format #t "Commit minde-binary.lock.scm with the configuration.~%")))
      (lambda () (delete-file-recursively directory)))))

(define (api-get url)
  "Fetch a public GitHub API URL as a string, with the filtered CA bundle."
  (let* ((directory (temporary-directory))
         (port #f))
    (dynamic-wind
      (lambda () (set-download-trust! (string-append directory "/trust")))
      (lambda ()
        (set! port (open-pipe* OPEN_READ "curl" "--fail" "--silent" "--show-error"
                               "--proto" "=https" "--proto-redir" "=https"
                               "--max-time" "30" "--retry" "2"
                               "--cacert" (getenv "SSL_CERT_FILE")
                               "-H" "Accept: application/vnd.github+json" url))
        (let ((text (get-string-all port)))
          (and (zero? (close-pipe port)) text)))
      (lambda () (delete-file-recursively directory)))))

(define (pinned-commit)
  (assoc-ref (read-metadata (string-append system-directory "/minde-binary.lock.scm"))
             'commit))

(define (ensure-pinned)
  (let ((pinned (read-metadata (string-append system-directory "/minde-binary.lock.scm"))))
    (unless (every (lambda (name) (file-exists? (assoc-ref pinned name)))
                   '(minde xwayland))
      (format #t "Pinned Minde binary ~a is not in this store; importing it.~%"
              (assoc-ref pinned 'commit))
      (install-release (assoc-ref pinned 'commit)))))

;; Update to the newest successful guix-binary run on main when it is ahead of
;; the lock. Looking it up is best effort (offline, rate limit): the pinned
;; build is then used. Anything chosen is verified by install-release exactly
;; like `make minde-install COMMIT=...`. MINDE_UPDATE=0 disables the lookup.
(define (update-pinned)
  (if (equal? (getenv "MINDE_UPDATE") "0")
      (begin (format #t "MINDE_UPDATE=0: keeping the pinned Minde build.~%")
             (ensure-pinned))
      (let* ((pinned (pinned-commit))
             (latest (catch #t
                       (lambda ()
                         (let ((text (api-get latest-run-url)))
                           (and text (latest-run-commit text))))
                       (lambda _ #f)))
             (status (and latest (not (string=? latest pinned))
                          (catch #t
                            (lambda ()
                              (let ((text (api-get (compare-url pinned latest))))
                                (and text (comparison-status text))))
                            (lambda _ #f)))))
        (cond
         ((not latest)
          (format #t "Could not determine the latest Minde build; keeping ~a.~%" pinned)
          (ensure-pinned))
         ((string=? latest pinned)
          (format #t "Minde is up to date (~a).~%" pinned)
          (ensure-pinned))
         ((equal? status "ahead")
          (format #t "Newer Minde build ~a (pinned: ~a); importing it.~%" latest pinned)
          (install-release latest))
         (else
          (format #t "Latest successful build ~a is not ahead of the pin (~a); keeping the pin.~%"
                  latest (or status "unknown"))
          (ensure-pinned))))))

(match (cdr (command-line))
  (("fetch" commit)
   (format #t "Verified download: ~a~%" (fetch-release commit)))
  (("install" commit) (install-release commit))
  ;; Import the pinned build only when it is missing from this store, e.g.
  ;; on another machine after the lock was bumped. Called by reconfigure.
  (("ensure") (ensure-pinned))
  (("update") (update-pinned))
  ;; Print the pinned commit (for the lock commit message).
  (("commit") (display (pinned-commit)) (newline))
  (("install")
   (install-release
    (assoc-ref (read-metadata (string-append system-directory "/minde-binary.lock.scm"))
               'commit)))
  (("verify" directory commit)
   (let ((temporary (temporary-directory)))
     (dynamic-wind
       (lambda () (set-download-trust! temporary))
       (lambda () (verify-release! directory commit))
       (lambda () (delete-file-recursively temporary)))))
  (("--import" directory commit) (import-release directory commit))
  (("--restore" directory) (restore-release directory))
  (_
   (display "usage: scripts/minde-binary.scm install [COMMIT]\n       scripts/minde-binary.scm ensure\n       scripts/minde-binary.scm update   (MINDE_UPDATE=0 keeps the pin)\n       scripts/minde-binary.scm fetch COMMIT\n       scripts/minde-binary.scm verify DIRECTORY COMMIT\n")
   (exit 2)))
