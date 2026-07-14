(define-module (services schemewm)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:export (schemewm-services))

(define schemewm-package
  ;; The shared selector retains the checkout fallback and accepts an explicit
  ;; RC archive through SCHEMEWM_RC_ARCHIVE + SCHEMEWM_RC_REVISION.
  (primitive-load "/home/samuel/Projects/System/schemewm-package.scm"))

(define personal-init
  (plain-file
   "schemewm-init.scm"
   "(setenv \"SCHEMEWM_CONFIG\"
        (string-append (getenv \"HOME\") \"/.config/schemewm/config.scm\"))
(primitive-load (string-append (getenv \"SCHEMEWM_SCHEME_DIR\") \"/init.scm\"))

;; Samuel's policy, layered over schemewm's portable C-t defaults.
(set-prefix-key! '() \"Print\")
(setenv \"SCHEMEWM_TERMINAL\" \"alacritty || foot || xterm\")

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
(let ((session-map (hash-ref %prefix-bindings \"s\")))
  (hash-set! session-map \"l\"
             (lambda () (wm-spawn \"swaylock -c 282828\")))
  (set-binding-doc! session-map \"l\" \"lock screen\"))

(define %personal-wallpaper
  (string-append
   \"img=$(for f in ~/Projects/images/*; do \"
   \"case \\\"$(head -c 4 \\\"$f\\\" 2>/dev/null | od -An -tx1 | tr -d ' \\\\n')\\\" in \"
   \"89504e47|ffd8ff*) echo \\\"$f\\\";; esac; done | shuf -n1); \"
   \"[ -n \\\"$img\\\" ] && swaybg -m fill -i \\\"$img\\\"\"))

(define (handle-startup!)
  (wm-spawn \"[ $(brightnessctl get) -lt 100 ] && brightnessctl set 80% || true\")
  (wm-spawn %personal-wallpaper)
  (wm-spawn \"eww open bar\")
  (wm-spawn \"eww open sysinfo\")
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
   "schemewm-config.scm"
   "(schemewm-config
 (version 1)
 (prefix () \"Print\")
 (bindings))
"))

(define (schemewm-services)
  (list
   (simple-service 'schemewm-package
                   home-profile-service-type
                   (list schemewm-package))
   (simple-service 'schemewm-config
                   home-xdg-configuration-files-service-type
                   `(("schemewm/init.scm" ,personal-init)
                     ("schemewm/config.scm" ,personal-config)))
   (simple-service 'schemewm-environment
                   home-environment-variables-service-type
                   '(("XKB_DEFAULT_LAYOUT" . "de")
                     ("XKB_DEFAULT_VARIANT" . "bone"))))))
