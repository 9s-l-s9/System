;;; Verified GitHub-built Minde releases. Data is read, never evaluated.
(define-module (lib minde-binary)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 textual-ports)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:use-module (rnrs bytevectors)
  #:use-module (gcrypt hash)
  #:use-module (guix base16)
  #:use-module (guix base64)
  #:use-module (guix build utils)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (minde-repository minde-workflow release-files
            run! full-commit? store-item? read-metadata read-closure
            file-digest set-download-trust! verify-release!
            prebuilt-minde-package))

(define minde-repository "9s-l-s9/minde")
(define minde-workflow
  "9s-l-s9/minde/.github/workflows/guix-binary.yml")
(define release-files
  '("binary.scm" "minde-x86_64-linux.nar.xz" "signing-key.pub"
    "closure.txt" "provenance.json"))

(define (run! . args)
  (unless (zero? (apply system* args))
    (error "command failed" (car args))))

(define (full-commit? value)
  (and (string? value) (string-match "^[0-9a-f]{40}$" value) #t))

(define (store-item? value)
  (and (string? value)
       (string-match "^/gnu/store/[0-9abcdfghijklmnpqrsvwxyz]{32}-[A-Za-z0-9+._?=-]+$" value)
       #t))

(define (hex-digest? value)
  (and (string? value) (string-match "^[0-9a-f]{64}$" value)))

(define (file-digest path)
  (bytevector->base16-string (file-sha256 path)))

(define (read-metadata file)
  (when (> (stat:size (stat file)) 16384)
    (error "oversized release metadata" file))
  (let ((data (call-with-input-file file
                (lambda (port)
                  (let ((value (read port)))
                    (unless (eof-object? (read port))
                      (error "trailing release metadata" file))
                    value)))))
    (unless (and (list? data)
                 (every (lambda (entry)
                          (and (pair? entry) (symbol? (car entry)))) data)
                 (lset= eq? (map car data)
                        '(schema repository commit version system minde xwayland
                          archive-sha256 key-sha256 closure-sha256))
                 (= (length data) 10)
                 (equal? (assoc-ref data 'schema) 1)
                 (equal? (assoc-ref data 'repository) minde-repository)
                 (full-commit? (assoc-ref data 'commit))
                 (equal? (assoc-ref data 'system) "x86_64-linux")
                 (let ((version (assoc-ref data 'version)))
                   (and (string? version)
                        (string-match "^[0-9][A-Za-z0-9.+-]*$" version)))
                 (every (lambda (key) (store-item? (assoc-ref data key)))
                        '(minde xwayland))
                 (string=? (string-drop (basename (assoc-ref data 'minde)) 33)
                           (string-append "minde-" (assoc-ref data 'version)))
                 (string-match "^xorg-server-xwayland-[0-9][A-Za-z0-9.+-]*$"
                               (string-drop (basename (assoc-ref data 'xwayland)) 33))
                 (every (lambda (key) (hex-digest? (assoc-ref data key)))
                        '(archive-sha256 key-sha256 closure-sha256)))
      (error "invalid Minde binary metadata" file))
    data))

(define (read-closure file metadata)
  (when (> (stat:size (stat file)) (* 1024 1024))
    (error "oversized closure list" file))
  (let ((paths (call-with-input-file file
                 (lambda (port)
                   (let loop ((result '()))
                     (let ((line (read-line port)))
                       (if (eof-object? line)
                           (reverse result)
                           (loop (cons line result)))))))))
    (unless (and (pair? paths) (every store-item? paths)
                 (= (length paths) (length (delete-duplicates paths)))
                 (member (assoc-ref metadata 'minde) paths)
                 (member (assoc-ref metadata 'xwayland) paths))
      (error "invalid Minde closure list" file))
    paths))

;; The affected eMudhra CA keys also had certificates cross-signed by AAA.
;; Old Guix channel snapshots still contain both roots. Exclude them by DER
;; fingerprint, including renamed certificates. Do not disable TLS checks.
;; https://bugzilla.mozilla.org/show_bug.cgi?id=2083449
(define blocked-roots
  '("86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b"
    "d7a7a0fb5d7e2731d771e9484ebcdef71d5f0c3e0a2948782bc83ee0ea699ef4"))

(define* (set-download-trust! directory
                              #:optional (source "/etc/ssl/certs/ca-certificates.crt"))
  (mkdir-p directory)
  (chmod directory #o700)
  (let ((destination (string-append directory "/ca-certificates.crt"))
        (empty (string-append directory "/empty"))
        (count 0))
    (mkdir-p empty)
    (call-with-output-file destination
      (lambda (output)
        (call-with-input-file source
          (lambda (input)
            (let loop ((lines #f))
              (let ((line (read-line input)))
                (cond
                 ((eof-object? line)
                  (when lines (error "truncated CA certificate" source)))
                 ((string=? line "-----BEGIN CERTIFICATE-----")
                  (when lines (error "nested CA certificate" source))
                  (loop '()))
                 ((string=? line "-----END CERTIFICATE-----")
                  (unless lines (error "invalid CA certificate" source))
                  (let* ((body (string-concatenate (reverse lines)))
                         (fingerprint
                          (bytevector->base16-string (sha256 (base64-decode body)))))
                    (unless (member fingerprint blocked-roots)
                      (set! count (+ count 1))
                      (display "-----BEGIN CERTIFICATE-----\n" output)
                      (display (string-join (reverse lines) "\n") output)
                      (display "\n-----END CERTIFICATE-----\n" output)))
                  (loop #f))
                 (else (loop (if lines (cons line lines) #f))))))))))
    (when (< count 50) (error "unexpected/empty CA bundle" source))
    (for-each (lambda (name) (setenv name destination))
              '("SSL_CERT_FILE" "CURL_CA_BUNDLE" "GIT_SSL_CAINFO"
                "CARGO_HTTP_CAINFO" "REQUESTS_CA_BUNDLE"))
    ;; Go (gh) and OpenSSL must not fall back to the unfiltered certificate dir.
    (setenv "SSL_CERT_DIR" empty)
    ;; TUF verifies its signed metadata but needs a writable cache. Keep it
    ;; private to this operation, including when invoked through sudo.
    (setenv "XDG_CACHE_HOME" (string-append directory "/cache"))
    destination))

(define (verify-release! directory commit)
  (unless (full-commit? commit) (error "a full commit hash is required" commit))
  (let ((metadata-file (string-append directory "/binary.scm")))
    (run! "gh" "attestation" "verify" metadata-file
          "--repo" minde-repository
          "--bundle" (string-append directory "/provenance.json")
          "--cert-identity" (string-append "https://github.com/" minde-workflow
                                           "@refs/heads/main")
          "--source-ref" "refs/heads/main"
          "--source-digest" commit "--signer-digest" commit
          "--deny-self-hosted-runners")
    (let ((metadata (read-metadata metadata-file)))
      (unless (string=? (assoc-ref metadata 'commit) commit)
        (error "release commit does not match requested commit"))
      (for-each
       (match-lambda
         ((file . key)
          (unless (string=? (file-digest (string-append directory "/" file))
                            (assoc-ref metadata key))
            (error "release checksum mismatch" file))))
       '(("minde-x86_64-linux.nar.xz" . archive-sha256)
         ("signing-key.pub" . key-sha256)
         ("closure.txt" . closure-sha256)))
      (read-closure (string-append directory "/closure.txt") metadata)
      metadata)))

(define (prebuilt-package name version path propagated license)
  (unless (file-exists? path)
    (error "Minde binary is not imported; run make minde-install COMMIT=<pinned commit>" path))
  (package
    (name name)
    (version version)
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list #:builder #~(symlink #$path #$output)))
    (propagated-inputs propagated)
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/9s-l-s9/minde")
    (synopsis "Verified GitHub-built Minde runtime")
    (description "An imported, attested Guix runtime closure. The local builder
only creates a symlink; it never compiles Rust or Guile sources.")
    (license license)))

(define (prebuilt-minde-package metadata)
  (let* ((xwayland (assoc-ref metadata 'xwayland))
         (xwayland-version
          (string-drop (basename xwayland)
                       (+ 33 (string-length "xorg-server-xwayland-")))))
    (prebuilt-package
     "minde" (assoc-ref metadata 'version) (assoc-ref metadata 'minde)
     (list (prebuilt-package "xorg-server-xwayland" xwayland-version
                             xwayland '() license:x11))
     license:gpl3+)))
