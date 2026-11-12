(define-module (privileged-scripts)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (privileged-script-services privileged-sudoers))

;; Only root-owned /etc links and immutable store files are trusted by sudo.
;; Never grant NOPASSWD for an interpreter loading the writable checkout.
(define %low-power-command "/etc/system-scripts/low-power-mode")
(define %keyboard-command "/etc/system-scripts/toggle-internal-keyboard")

(define low-power-program
  (program-file "low-power-mode"
    #~(begin
        (unless (null? (cdr (command-line))) (exit 2))
        (primitive-load #$(local-file "../scripts/low-power-mode.scm")))))

(define keyboard-program
  (program-file "toggle-internal-keyboard"
    #~(begin
        (unless (member (cdr (command-line)) '(() ("on") ("off")))
          (exit 2))
        (primitive-load #$(local-file "../scripts/toggle-internal-keyboard.scm")))))

(define* (privileged-script-services #:key (keyboard? #f))
  (list (simple-service
         'privileged-scripts etc-service-type
         `(("system-scripts/low-power-mode" ,low-power-program)
           ,@(if keyboard?
                 `(("system-scripts/toggle-internal-keyboard" ,keyboard-program))
                 '())))))

(define* (privileged-sudoers user #:key (keyboard? #f))
  (plain-file
   "sudoers"
   (string-append
    "root ALL=(ALL) ALL\n"
    "%wheel ALL=(ALL) ALL\n"
    user " ALL=(root) NOPASSWD: " %low-power-command " \"\""
    (if keyboard?
        (string-append ", " %keyboard-command " \"\", "
                       %keyboard-command " on, " %keyboard-command " off")
        "")
    "\n")))
