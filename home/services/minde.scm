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
(set-prefix-key! '() \"Print\")
(setenv \"MINDE_TERMINAL\" \"foot || konsole\")

(bind-prefix-key! \"b\"
  (lambda () (wm-spawn \"MOZ_ENABLE_WAYLAND=1 zen || chromium --ozone-platform-hint=auto\"))
  \"browser\")
(bind-prefix-key! \"e\" (lambda () (wm-spawn \"lem -i sdl2\")) \"Lem\")
(bind-prefix-key! \"E\" (lambda () (wm-spawn \"emacsclient -c -a emacs\")) \"Emacs\")
(bind-prefix-key! \"i\" (lambda () (wm-spawn \"eww open --toggle sysinfo\")) \"eww widgets\")
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

;; One eww bar per enabled monitor.  (wm-outputs) entries are
;; (id x y w h name); --screen selects the Wayland connector, --id lets
;; separate instances of the same bar window coexist.  Re-run after
;; every output change so a bar appears on a newly enabled head and the
;; bar of a disabled head is closed (its output is gone anyway).
(define (sync-bars!)
  (for-each
   (lambda (output)
     (let ((name (list-ref output 5)))
       (wm-spawn (string-append \"eww open bar --id bar-\" name
                                \" --screen \" name))))
   (wm-outputs))
  (when (defined? 'output-heads)
    (for-each
     (lambda (head)
       (unless (assq-ref head 'enabled)
         (wm-spawn (string-append \"eww close bar-\"
                                  (assq-ref head 'name)))))
     (output-heads))))

;; Runs after an output-management client (shikane, wlr-randr) or
;; configure-output! changed the layout.
(define (handle-output-configured!)
  (sync-bars!))

(define (handle-startup!)
  ;; Output layout first: shikane applies the matching profile from
  ;; ~/.config/shikane/config.toml now and on every hotplug; the bars
  ;; follow through handle-output-configured!.
  (wm-spawn \"shikane\")
  ;; Wallpaper and widgets -- they are the visible part of startup.
  (wm-spawn %personal-wallpaper)
  (wm-spawn \"eww open sysinfo\")
  (sync-bars!)
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
