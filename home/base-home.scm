;;; base-home.scm --- Shared home-environment building blocks
;;;
;;; Both per-user entry points (samuel, levi) compose their final
;;; `home-environment' on top of the helpers exported here:
;;;
;;;   - `base-services'  returns the services every user shares
;;;     (Minde, git, Emacs, agent integration, dotfiles tree).
;;;   - per-user files add their user-specific services on top.

(define-module (base-home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services sound)
  #:use-module (services minde)
  #:use-module (services git)
  #:use-module (services emacs)
  #:use-module (services agent-skills)
  #:use-module (services agent-launchers)
  #:export (base-services))

(define (base-services)
  "Services shared by every user's home environment."
  (append
   (list
   ;; Audio stack: PipeWire + WirePlumber as user services, with
   ;; pipewire-pulse providing the PulseAudio-compatible socket (so pactl,
   ;; whisper's alsa_input.* source names, etc. keep working). This is also
   ;; what handles Bluetooth audio, talking to the system bluetoothd —
   ;; no bluez-alsa, no real PulseAudio daemon (autospawn is off in
   ;; base-system.scm). Requires the D-Bus user session below.
   (service home-dbus-service-type)
   (service home-pipewire-service-type)
   (git-service)
   (emacs-daemon-service)
   (agent-skills-service)
   (service home-dotfiles-service-type
            (home-dotfiles-configuration
             (directories '("./files")))))
   (agent-launcher-services)
   (minde-services)))
