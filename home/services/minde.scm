(define-module (services minde)
  #:use-module (gnu home services)
  #:use-module (gnu packages)
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
    # minde applies this for real since da12c1f.  Native 4K only reaches
    # 24Hz over this HDMI 1.4 link, which feels laggy and renders tiny at
    # scale 1.0; 1440p@60 is the usable compromise until DisplayPort.
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

;;
;; RULE: all keybindings go through the Print prefix key.  Never bind
;; Super, Ctrl, Alt, or any other modifier chord — prefix + plain key
;; (or Shift-key, or a sub-keymap) only.
(set-prefix-key! '() \"Print\")
(setenv \"MINDE_TERMINAL\" \"foot\")

(bind-prefix-key! \"b\"
  (lambda () (wm-spawn \"MOZ_ENABLE_WAYLAND=1 zen || chromium --ozone-platform-hint=auto\"))
  \"browser\")
(bind-prefix-key! \"e\" (lambda () (wm-spawn \"lem -i sdl2\")) \"Lem\")
(bind-prefix-key! \"E\" (lambda () (wm-spawn \"emacsclient -c -a emacs\")) \"Emacs\")
(bind-prefix-key! \"i\"
  (lambda () (eww-run! (list \"eww open --toggle sysinfo\")))
  \"eww widgets\")
(bind-prefix-key! \"a\"
  (lambda () (toggle-actions!))
  \"command center\")
;; Toggle the corrosion-damaged internal keyboard (i8042 controller unbind).
;; Must be the exact command from the NOPASSWD sudoers rule in
;; systems/X1.scm (guile + script path); ~/.local/bin/toggle-internal-kbd
;; used sudo tee, which the rule does not cover, so it silently failed.
(bind-prefix-key! \"K\"
  (lambda ()
    (wm-spawn
     (string-append
      \"sudo -n /run/current-system/profile/bin/guile\"
      \" -s /home/samuel/Projects/System/scripts/toggle-internal-keyboard.scm\"
      \" && notify-send 'Internal keyboard' toggled\")))
  \"toggle internal keyboard\")
;; Re-pair the ERGO M575 after it was used on another computer (it then
;; presents a new address and rejects the old bond).  Mouse must be in
;; pairing mode; the script drops stale bonds, scans, pairs, trusts, connects.
(bind-prefix-key! \"M\"
  (lambda () (wm-spawn \"~/Projects/System/scripts/pair-ergo-mouse.scm\"))
  \"re-pair ERGO mouse\")
;; Super-low-power toggle: min CPU freq, no turbo, half the cores off,
;; firmware low-power profile.  Run again to restore.  Needs the
;; NOPASSWD sudoers rule from systems/X1.scm (exact guile + script path).
(bind-prefix-key! \"L\"
  (lambda ()
    (wm-spawn
     (string-append
      \"sudo /run/current-system/profile/bin/guile\"
      \" -s ~/Projects/System/scripts/low-power-mode.scm\"
      \" && notify-send 'Low power' toggled\")))
  \"low power mode\")
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
;; ~3 s on a cold cache.  Only replace swaybg after finding a real image.
;; Serialize requests so rapid clicks cannot leave multiple backgrounds.
;; Close the lock fd on exec so the new swaybg does not retain it.
(define %personal-wallpaper
  (string-append
   \"exec 9>${XDG_RUNTIME_DIR:-/tmp}/minde-wallpaper-$(id -u).lock; \"
   \"flock 9 || exit 1; \"
   \"img=$(find \\\"$HOME/Projects/images\\\" -maxdepth 1 -type f \"
   \"\\\\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \\\\) \"
   \"-print | shuf -n1); \"
   \"[ -f \\\"$img\\\" ] || exit 1; \"
   \"pkill -u \\\"$(id -u)\\\" -x swaybg || true; \"
   \"exec swaybg -m fill -i \\\"$img\\\" 9>&-\"))

(define (next-wallpaper!)
  (wm-spawn %personal-wallpaper))

;; The Emacs daemon is a Shepherd service (emacs.scm) and starts without
;; the compositor's WAYLAND_DISPLAY/DISPLAY, so eat shells, dired and
;; browse-url could not open GUI programs (\"no DISPLAY\").  minde exports
;; both only to its own children, so hand them over from here: record
;; them for later daemon (re)starts and push them into the running one.
;; DISPLAY appears once Xwayland is ready, possibly after this spawn;
;; fall back to the Xwayland process's display argument.
(define %emacs-session-env
  (string-append
   \"f=${XDG_RUNTIME_DIR:-/tmp}/graphical-session.env; d=$DISPLAY; \"
   \"for _ in $(seq 50); do [ -n \\\"$d\\\" ] && break; \"
   \"d=$(pgrep -u \\\"$(id -u)\\\" -a Xwayland | grep -o ' :[0-9]*' \"
   \"| head -n1 | tr -d ' '); [ -n \\\"$d\\\" ] || sleep 0.2; done; \"
   \"{ echo \\\"WAYLAND_DISPLAY=$WAYLAND_DISPLAY\\\"; \"
   \"if [ -n \\\"$d\\\" ]; then echo \\\"DISPLAY=$d\\\"; fi; } > \\\"$f.tmp\\\" \"
   \"&& mv \\\"$f.tmp\\\" \\\"$f\\\"; \"
   \"el=\\\"(progn (setenv \\\\\\\"WAYLAND_DISPLAY\\\\\\\" \\\\\\\"$WAYLAND_DISPLAY\\\\\\\")\\\"; \"
   \"[ -n \\\"$d\\\" ] && el=\\\"$el (setenv \\\\\\\"DISPLAY\\\\\\\" \\\\\\\"$d\\\\\\\")\\\"; \"
   \"el=\\\"$el)\\\"; \"
   \"for _ in $(seq 100); do \"
   \"emacsclient -e \\\"$el\\\" >/dev/null 2>&1 && exit 0; sleep 0.2; done\"))

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
;; answer before opening anything. Close fd 9 in every Eww subprocess so
;; even an automatically started daemon cannot retain the batch lock.
;; Bound both lock acquisition and readiness waits.
(define (eww-run! commands)
  (unless (null? commands)
    (wm-spawn
     (let loop ((rest commands)
                (script (string-append
                         \"exec 9>${XDG_RUNTIME_DIR:-/tmp}/eww-sync.lock; \"
                         \"flock -w 10 9 || exit 1; \"
                         \"eww ping 9>&- >/dev/null 2>&1 || eww daemon 9>&-; \"
                         \"for _ in $(seq 200); do \"
                         \"eww ping 9>&- >/dev/null 2>&1 && break; \"
                         \"sleep 0.05; done; \"
                         \"eww ping 9>&- >/dev/null 2>&1 || exit 1\")))
       (if (null? rest)
           script
           (loop (cdr rest)
                 (string-append script \"; ( \" (car rest) \" ) 9>&-\")))))))

(define (personal-shell-quote text)
  (string-append \"'\"
                 (string-join (string-split text (integer->char 39)) \"'\\\\''\")
                 \"'\"))

;; wm-outputs reports usable height below the bar.  Width stays a monitor
;; percentage in Eww because opening the pane changes the usable width.
(define (toggle-actions!)
  (let* ((outputs (wm-outputs))
         (output (or (assv (current-head-id) outputs)
                     (and (pair? outputs) (car outputs)))))
    (when output
      (eww-run!
       (list (string-append
              \"eww open --toggle actions --screen \"
              (personal-shell-quote (list-ref output 5))
              \" --arg pane-height=\" (number->string (list-ref output 4))))))))

;; One eww bar per enabled monitor.  (wm-outputs) entries are
;; (id x y w h name); --screen selects the Wayland connector, --id lets
;; separate instances of the same bar window coexist.  Close a connector's
;; existing ID before opening it: shikane may report the same applied profile
;; more than once, and Eww otherwise leaves duplicate exclusive layer surfaces
;; behind even though `eww active-windows` shows only the newest ID.  Re-run after
;; every output change so a bar appears on a newly enabled head and the
;; bar of a disabled head is closed (its output is gone anyway).
(define (bar-commands)
  (let ((opens (map (lambda (output)
                      (let ((name (list-ref output 5)))
                        (string-append \"eww close bar-\" name \"; \"
                                       \"eww open bar --id bar-\" name
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
  ;; Minimal sessions do not start a desktop environment's Polkit agent.
  ;; This one supplies the password dialog used by the internal-keyboard
  ;; toggle; it grants no privileges by itself.
  (wm-spawn \"~/.guix-home/profile/libexec/polkit-gnome-authentication-agent-1\")
  ;; Wallpaper and widgets -- they are the visible part of startup.
  (next-wallpaper!)
  ;; sysinfo rides in the bars' batch rather than racing it: see eww-run!.
  (eww-run! (cons \"eww open sysinfo\" (bar-commands)))
  ;; Same temperatures/location the old X11 redshift service used before it
  ;; was removed as dead (Wayland-only session now); needs minde's
  ;; wlr-gamma-control support.
  (wm-spawn \"gammastep -m wayland -l 35.81:-0.80 -t 3500:3000\")
  (wm-spawn \"[ $(brightnessctl get) -lt 100 ] && brightnessctl set 80% || true\")
  ;; A reboot mid-eco leaves Bluetooth rfkill-blocked (firmware remembers
  ;; the switch) plus a stale state file; clear both so Print h and the
  ;; Bluetooth mouse behave. Idempotent when eco mode is not on.
  (wm-spawn \"~/Projects/System/scripts/eco-toggle.scm off\")
  ;; KDE Connect has no Plasma session to D-Bus-activate its daemon, so start
  ;; it here; without a running kdeconnectd the phone never discovers this PC.
  ;; The indicator gives a tray entry for pairing/sending files.
  (wm-spawn \"kdeconnectd\")
  (wm-spawn \"kdeconnect-indicator\")
  (wm-spawn %emacs-session-env)
  ;; Sync Mailfence right away instead of waiting up to five minutes for
  ;; the mail-sync timer after a reboot.
  (wm-spawn \"herd trigger mail-sync\")
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
                   (list minde-package
                         shikane-package
                         (specification->package "polkit-gnome")))
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
                     ("XKB_DEFAULT_VARIANT" . "bone,")
                     ;; Firefox-based browsers (Zen) keep one profile per
                     ;; install *path*; every Guix update moves the store
                     ;; path and would start a fresh empty profile.  Legacy
                     ;; mode uses the Default=1 profile from profiles.ini
                     ;; regardless of where the binary lives.
                     ("MOZ_LEGACY_PROFILES" . "1")))))
