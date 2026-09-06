;; Shared helpers for the agent launcher scripts (claude-guix, codex-guix,
;; pi-guix, dsh-guix, open-code-guix). Kept deliberately small: only the bits
;; that were byte-for-byte identical (or safely parameterisable) across all
;; five scripts live here. Anything that differs per-tool (parse-args shape,
;; sandbox mounts, the inline bash command) stays in the individual scripts.

(define-module (agent-launch)
  #:use-module (ice-9 format)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (env
            require-home
            mode-name
            expand-user-path
            resolve-directory
            maybe-mount
            maybe-preserve
            container-socket-mounts
            ensure-directory
            xdg-runtime-expose
            guix-profiles-expose
            preserve-common-env
            git-config-mounts
            maybe-dry-run
            run-guix))

(define (env name default)
  (or (getenv name) default))

;; Look up $HOME, or print "NAME: HOME is not set." and exit 1.
(define (require-home name)
  (or (getenv "HOME")
      (begin
        (format (current-error-port) "~a: HOME is not set.~%" name)
        (exit 1))))

(define (mode-name mode)
  (case mode
    ((full) "full")
    ((host) "host")
    (else "sandbox")))

;; Expand a leading ~ or ~/ against HOME.
(define (expand-user-path home path)
  (cond
    ((string=? path "~") home)
    ((string-prefix? "~/" path)
     (string-append home (substring path 1)))
    (else path)))

;; Turn a relative path into an absolute one, relative to the cwd.
(define (resolve-directory path)
  (if (string-prefix? "/" path)
      path
      (string-append (getcwd) "/" path)))

;; Expose/share SOURCE at TARGET only when SOURCE actually exists on the host.
(define (maybe-mount flag source target)
  (if (and source (file-exists? source))
      (list (string-append flag "=" source "=" target))
      '()))

;; Preserve an env var into the container only when it is set on the host.
(define (maybe-preserve name)
  (if (getenv name)
      (list (string-append "--preserve=^" name "$"))
      '()))

;; Host Docker/Podman sockets for container-backed tools.
(define (container-socket-mounts)
  (append
   (maybe-mount "--expose" "/var/run/docker.sock" "/var/run/docker.sock")
   (let ((xdg-runtime (getenv "XDG_RUNTIME_DIR")))
     (if xdg-runtime
         (append
          (maybe-mount "--expose"
                       (string-append xdg-runtime "/docker.sock")
                       (string-append xdg-runtime "/docker.sock"))
          (maybe-mount "--expose"
                       (string-append xdg-runtime "/podman/podman.sock")
                       (string-append xdg-runtime "/podman/podman.sock")))
         '()))))

(define (ensure-directory path)
  (unless (file-exists? path)
    (mkdir path)))

;; runtime / display: expose XDG_RUNTIME_DIR itself when present.
(define (xdg-runtime-expose)
  (let ((xdg-runtime (getenv "XDG_RUNTIME_DIR")))
    (if (and xdg-runtime (file-exists? xdg-runtime))
        (list (string-append "--expose=" xdg-runtime "=" xdg-runtime))
        '())))

;; Inside the container, /var/guix only has the daemon socket -- the host's
;; /var/guix/profiles (generations for guix home/pull/package/system) is
;; missing, so `guix home list-generations` and friends fail with "profile
;; ... does not exist". Expose it read-only so those commands work.
(define (guix-profiles-expose)
  (maybe-mount "--expose" "/var/guix/profiles" "/var/guix/profiles"))

;; The full set of env vars preserved by claude-guix, codex-guix, pi-guix and
;; open-code-guix's sandbox mode.
(define (preserve-common-env)
  (append
   (maybe-preserve "DBUS_SESSION_BUS_ADDRESS")
   (maybe-preserve "COLORTERM")
   (maybe-preserve "CONTAINER_HOST")
   (maybe-preserve "DISPLAY")
   (maybe-preserve "DOCKER_HOST")
   (maybe-preserve "WAYLAND_DISPLAY")
   (maybe-preserve "XDG_RUNTIME_DIR")
   (maybe-preserve "XAUTHORITY")))

;; git config (read-only), exposed under HOME so `git` inside the container
;; still knows the user's identity.
(define (git-config-mounts home)
  (append
   (maybe-mount "--expose"
                (string-append home "/.config/git/config")
                (string-append home "/.config/git/config"))
   (maybe-mount "--expose"
                (string-append home "/.gitconfig")
                (string-append home "/.gitconfig"))))

;; When AGENT_LAUNCH_DRY_RUN is set, print ARGS (one element per line)
;; instead of executing anything, and exit 0 -- this lets the launcher
;; scripts be verified without actually spawning a container.
(define (maybe-dry-run args)
  (when (getenv "AGENT_LAUNCH_DRY_RUN")
    (for-each (lambda (a) (format #t "~a~%" a)) args)
    (exit 0)))

;; Run `guix ARGS...`, reporting failures as "NAME: guix shell exited with
;; status N".
(define (run-guix name args)
  (maybe-dry-run args)
  (let ((status (apply system* "guix" args)))
    (if (zero? status)
        (exit 0)
        (begin
          (format (current-error-port)
                  "~a: guix shell exited with status ~a~%" name status)
          (exit 1)))))
