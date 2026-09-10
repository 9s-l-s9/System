(define-module (services minde)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:export (minde-services))

(define minde-package
  ;; The shared selector retains the checkout fallback and accepts an explicit
  ;; RC archive through MINDE_RC_ARCHIVE + MINDE_RC_REVISION.
  (primitive-load "/home/samuel/Projects/System/minde-package.scm"))

;; shikane (wlr-output-management profile daemon) lives in minde's own
;; channel until it reaches upstream Guix.
(eval-when (expand load eval)
  (add-to-load-path "/home/samuel/Projects/minde/guix-channel"))
(define shikane-package
  (module-ref (resolve-interface '(minde packages)) 'shikane))

;; Output profiles: shikane picks the one whose outputs match every
;; connected display and applies it on login and on every hotplug.  The
;; Samsung is matched by serial so a second identical model would not
;; collide; the laptop panel by connector name.  Over the X1 Yoga's HDMI
;; 1.4 port 2560x1440@60 is the sharpest full-RGB mode (4K only at 24 Hz,
;; chroma-subsampled); switch to 3840x2160@60 + scale 1.5 once the
;; monitor hangs off DisplayPort.
(define shikane-config
  (plain-file
   "shikane-config.toml"
   "[[profile]]
name = \"samsung-only\"

    [[profile.output]]
    search = [\"m=LC32G7xT\", \"s=H4ZT101963\"]
    enable = true
    mode = \"2560x1440@59.951Hz\"
    position = \"0,0\"
    scale = 1.0

    [[profile.output]]
    search = \"n=eDP-1\"
    enable = false

[[profile]]
name = \"laptop-only\"

    [[profile.output]]
    search = \"n=eDP-1\"
    enable = true
    mode = \"preferred\"
    position = \"0,0\"
    scale = 1.0
"))

(define personal-init
  (plain-file
   "minde-init.scm"
   "(setenv \"MINDE_CONFIG\"
        (string-append (getenv \"HOME\") \"/.config/minde/config.scm\"))
(primitive-load (string-append (getenv \"MINDE_SCHEME_DIR\") \"/init.scm\"))

;; Samuel's policy, layered over minde's portable C-t defaults.
;; StumpWM-style padding: each window edge, outer edges, and the head.
(configure-gaps! #:inner 5 #:outer 10 #:head 20)
(gaps-on!)

(set-prefix-key! '() \"Print\")
(setenv \"MINDE_TERMINAL\" \"foot || konsole\")

(bind-prefix-key! \"b\"
  (lambda () (wm-spawn \"MOZ_ENABLE_WAYLAND=1 zen || chromium --ozone-platform-hint=auto\"))
  \"browser\")
(bind-prefix-key! \"e\" (lambda () (wm-spawn \"lem -i sdl2\")) \"Lem\")
(bind-prefix-key! \"E\" (lambda () (wm-spawn \"emacsclient -c -a emacs\")) \"Emacs\")
(bind-prefix-key! \"i\"
  (lambda () (eww-run! (list \"eww open --toggle sysinfo\")))
  \"eww widgets\")
(bind-prefix-key! \"A\"
  (make-keymap
   \"c\" (lambda () (wm-spawn \"foot -e ~/Projects/System/scripts/codex-guix.scm\"))
   \"d\" (lambda () (wm-spawn \"foot -e ~/Projects/System/scripts/claude-guix.scm\"))
   \"h\" (lambda () (wm-spawn \"foot -e ~/Projects/System/scripts/dsh-guix.scm\"))
   \"o\" (lambda () (wm-spawn \"foot -e ~/Projects/System/scripts/open-code-guix.scm\"))
   \"p\" (lambda () (wm-spawn \"foot -e ~/Projects/System/scripts/pi-guix.scm\")))
  \"agents\")
(bind-prefix-key! \"V\"
  (lambda () (wm-spawn \"~/Projects/System/scripts/voice-dictate.scm\"))
  \"voice dictation\")
;; Eco toggle (replaces the plain brightness 0/60 toggle): backlight off,
;; turbo off, Zen SIGSTOPped, bluetooth blocked -- Wi-Fi stays up so agent
;; sessions keep running. Second press restores everything.
(bind-prefix-key! \"h\"
  (lambda () (wm-spawn \"~/Projects/System/scripts/eco-toggle.scm\"))
  \"eco mode on/off\")
;; Print X: flip the XKB layout group between de(bone) (built-in
;; keyboard) and us (the Corne, whose firmware already implements Bone
;; on top of a US host layout).  Groups come from XKB_DEFAULT_LAYOUT
;; below; handle-keyboard-layout-changed! shows the new name.
(when (defined? 'set-keyboard-layout!)
  (bind-prefix-key! \"X\" (lambda () (set-keyboard-layout! 'next))
                    \"keyboard layout de(bone)/us\"))
;; swaylock with the personal background color. The base config binds
;; s l -> lock-screen! and s z -> suspend! ((minde session)); both
;; honor %lock-command, so no personal rebinding is needed anymore.
;; (defined?-guarded so this overlay still loads on a pre-session
;; minde.)
(when (defined? '%lock-command)
  (set! %lock-command \"swaylock -f -c 282828\"))

;; Pick by extension instead of sniffing magic bytes: the old loop forked
;; head+od per file (~340 processes over 170 images) and delayed swaybg by
;; ~3 s on a cold cache.  exec replaces the shell so swaybg is the direct
;; child.
(define %personal-wallpaper
  (string-append
   \"img=$(shuf -e -n1 ~/Projects/images/*.png \"
   \"~/Projects/images/*.jpg ~/Projects/images/*.jpeg); \"
   \"[ -n \\\"$img\\\" ] && exec swaybg -m fill -i \\\"$img\\\"\"))

;; eww's client starts a daemon when none answers, and it detaches
;; before that daemon listens.  Two `eww open' processes launched
;; together therefore both conclude \"no daemon\", both try to become
;; one, and the loser's window request is dropped -- which is how the
;; bar went missing while sysinfo, spawned a moment earlier, stayed up.
;; Nothing repaired it afterwards once minde stopped re-firing
;; handle-output-configured! for a profile shikane re-applied unchanged;
;; that redundant second sync was what used to open the bar on a second
;; pass (and, before minde suppressed it, what duplicated bars).  So
;; every eww command goes through one shell: flock serialises it against
;; a concurrent output hook, and the batch waits for the daemon to
;; answer before opening anything. Close fd 9 in the daemon so it
;; cannot retain the lock after the batch exits; abort on readiness timeout.
(define (eww-run! commands)
  (unless (null? commands)
    (wm-spawn
     (let loop ((rest commands)
                (script (string-append
                         \"exec 9>${XDG_RUNTIME_DIR:-/tmp}/eww-sync.lock; \"
                         \"flock 9 || exit 1; \"
                         \"eww ping >/dev/null 2>&1 || eww daemon 9>&-; \"
                         \"for _ in $(seq 200); do \"
                         \"eww ping >/dev/null 2>&1 && break; \"
                         \"sleep 0.05; done; \"
                         \"eww ping >/dev/null 2>&1 || exit 1\")))
       (if (null? rest)
           script
           (loop (cdr rest) (string-append script \"; \" (car rest))))))))

;; One eww bar per enabled monitor.  (wm-outputs) entries are
;; (id x y w h name); --screen selects the Wayland connector, --id lets
;; separate instances of the same bar window coexist.  Re-run after
;; every output change so a bar appears on a newly enabled head and the
;; bar of a disabled head is closed (its output is gone anyway).
(define (bar-commands)
  (let ((opens (map (lambda (output)
                      (let ((name (list-ref output 5)))
                        (string-append \"eww open bar --id bar-\" name
                                       \" --screen \" name)))
                    (wm-outputs))))
    (if (defined? 'output-heads)
        (let loop ((heads (output-heads)) (closes '()))
          (cond
           ((null? heads) (append opens (reverse closes)))
           ((assq-ref (car heads) 'enabled) (loop (cdr heads) closes))
           (else
            (loop (cdr heads)
                  (cons (string-append \"eww close bar-\"
                                       (assq-ref (car heads) 'name))
                        closes)))))
        opens)))

(define (sync-bars!)
  (eww-run! (bar-commands)))

;; Runs after an output-management client (shikane, wlr-randr) or
;; configure-output! changed the layout.
(define (handle-output-configured!)
  (sync-bars!))

(define (handle-startup!)
  ;; Output layout first: shikane applies the matching profile from
  ;; ~/.config/shikane/config.toml now and on every hotplug.  The bars
  ;; are opened here rather than left to handle-output-configured!:
  ;; minde stays silent when a re-applied profile changes nothing, so
  ;; that hook only covers later layout changes.
  (wm-spawn \"shikane\")
  ;; Wallpaper and widgets -- they are the visible part of startup.
  (wm-spawn %personal-wallpaper)
  ;; sysinfo rides in the bars' batch rather than racing it: see eww-run!.
  (eww-run! (cons \"eww open sysinfo\" (bar-commands)))
  ;; Same temperatures/location the old X11 redshift service used before it
  ;; was removed as dead (Wayland-only session now); needs minde's
  ;; wlr-gamma-control support.
  (wm-spawn \"gammastep -m wayland -l 35.81:-0.80 -t 3500:3000\")
  (wm-spawn \"[ $(brightnessctl get) -lt 100 ] && brightnessctl set 80% || true\")
  ;; KDE Connect has no Plasma session to D-Bus-activate its daemon, so start
  ;; it here; without a running kdeconnectd the phone never discovers this PC.
  ;; The indicator gives a tray entry for pairing/sending files.
  (wm-spawn \"kdeconnectd\")
  (wm-spawn \"kdeconnect-indicator\")
  (wm-log \"personal autostart complete\"))

;; Preserve personal additions across the base configuration's atomic reload.
(if (defined? 'register-configuration-layer!)
    (register-configuration-layer!)
    (begin
      (set! %configuration-base-bindings #f)
      (set! %configuration-base-docs #f)
      (capture-configuration-base!)))
"))

(define personal-config
  (plain-file
   "minde-config.scm"
   "(minde-config
 (version 1)
 (prefix () \"Print\")
 (bindings))
"))

(define (minde-services)
  (list
   (simple-service 'minde-package
                   home-profile-service-type
                   (list minde-package shikane-package))
   (simple-service 'minde-config
                   home-xdg-configuration-files-service-type
                   `(("minde/init.scm" ,personal-init)
                     ("minde/config.scm" ,personal-config)
                     ("shikane/config.toml" ,shikane-config)))
   (simple-service 'minde-environment
                   home-environment-variables-service-type
                   ;; Two layout groups: de(bone) for the built-in keyboard
                   ;; and plain us for the Corne; Print X switches (see
                   ;; personal-init), so no grp:* chord is configured.
                   '(("XKB_DEFAULT_LAYOUT" . "de,us")
                     ("XKB_DEFAULT_VARIANT" . "bone,")))))
