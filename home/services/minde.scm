(define-module (services minde)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:export (minde-services))

(define minde-package
  ;; The shared selector retains the checkout fallback and accepts an explicit
  ;; RC archive through MINDE_RC_ARCHIVE + MINDE_RC_REVISION.
  (primitive-load "/home/samuel/Projects/System/minde-package.scm"))

(define personal-init
  (plain-file
   "minde-init.scm"
   "(setenv \"MINDE_CONFIG\"
        (string-append (getenv \"HOME\") \"/.config/minde/config.scm\"))
(primitive-load (string-append (getenv \"MINDE_SCHEME_DIR\") \"/init.scm\"))

;; Samuel's policy, layered over minde's portable C-t defaults.
(set-prefix-key! '() \"Print\")
(setenv \"MINDE_TERMINAL\" \"alacritty || foot || xterm\")

(bind-prefix-key! \"b\"
  (lambda () (wm-spawn \"MOZ_ENABLE_WAYLAND=1 zen || chromium --ozone-platform-hint=auto\"))
  \"browser\")
(bind-prefix-key! \"e\" (lambda () (wm-spawn \"lem -i sdl2\")) \"Lem\")
(bind-prefix-key! \"E\" (lambda () (wm-spawn \"emacsclient -c -a emacs\")) \"Emacs\")
(bind-prefix-key! \"i\" (lambda () (wm-spawn \"eww open --toggle sysinfo\")) \"eww widgets\")
(bind-prefix-key! \"A\"
  (make-keymap
   \"c\" (lambda () (wm-spawn \"alacritty -e ~/Projects/System/scripts/codex-guix.scm\"))
   \"d\" (lambda () (wm-spawn \"alacritty -e ~/Projects/System/scripts/claude-guix.scm\"))
   \"o\" (lambda () (wm-spawn \"alacritty -e ~/Projects/System/scripts/open-code-guix.scm\"))
   \"p\" (lambda () (wm-spawn \"alacritty -e ~/Projects/System/scripts/pi-guix.scm\")))
  \"agents\")
(bind-prefix-key! \"V\"
  (lambda () (wm-spawn \"~/Projects/System/scripts/voice-dictate.scm\"))
  \"voice dictation\")
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

(define (handle-startup!)
  ;; Wallpaper and widgets first -- they are the visible part of startup.
  ;; One eww invocation: two parallel `eww open` calls race to autostart
  ;; the daemon and both pay its init.
  (wm-spawn %personal-wallpaper)
  (wm-spawn \"eww open-many bar sysinfo\")
  ;; Same temperatures/location as the X11 redshift service
  ;; (services/redshift.scm); needs minde's wlr-gamma-control support.
  (wm-spawn \"gammastep -m wayland -l 35.81:-0.80 -t 3500:3000\")
  (wm-spawn \"[ $(brightnessctl get) -lt 100 ] && brightnessctl set 80% || true\")
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
                   (list minde-package))
   (simple-service 'minde-config
                   home-xdg-configuration-files-service-type
                   `(("minde/init.scm" ,personal-init)
                     ("minde/config.scm" ,personal-config)))
   (simple-service 'minde-environment
                   home-environment-variables-service-type
                   '(("XKB_DEFAULT_LAYOUT" . "de")
                     ("XKB_DEFAULT_VARIANT" . "bone")))))
