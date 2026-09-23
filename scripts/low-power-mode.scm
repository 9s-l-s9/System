#!/usr/bin/env -S guile -s
!#

;; Toggle a "super low power" mode: cap every CPU at its minimum
;; frequency, kill turbo/boost, prefer the powersave energy policy,
;; take half the cores offline, and ask the firmware for its
;; low-power platform profile.  Interactive work (a Claude session,
;; an editor) stays usable on the remaining minimum-frequency cores;
;; everything just gets slow instead of hot.
;;
;; Needs root for the sysfs writes — run it as
;;   sudo guile -s ~/Projects/System/scripts/low-power-mode.scm
;; or via pkexec like toggle-internal-keyboard.scm.  Session-only:
;; a reboot restores normal defaults, and running it again while low
;; restores them immediately.  cpu0 can never be offlined (no
;; `online` file), which also guarantees at least one core survives.

(use-modules (ice-9 format)
             (ice-9 ftw)
             (ice-9 rdelim))

(define (sysfs-read path)
  (and (file-exists? path)
       (call-with-input-file path
         (lambda (port)
           (string-trim-both (read-string port))))))

(define (sysfs-write path value)
  (if (file-exists? path)
      (catch #t
        (lambda ()
          (call-with-output-file path
            (lambda (port) (display value port)))
          #t)
        (lambda (key . args)
          (format (current-error-port) "  skip ~a (~a)~%" path key)
          #f))
      #f))

(define (cpu-policies)
  (sort
   (map (lambda (d) (string-append "/sys/devices/system/cpu/cpufreq/" d))
        (or (scandir "/sys/devices/system/cpu/cpufreq"
                     (lambda (d) (string-prefix? "policy" d)))
            '()))
   string<?))

(define (cpu-online-files)
  (sort
   (filter file-exists?
           (map (lambda (d) (string-append "/sys/devices/system/cpu/" d "/online"))
                (or (scandir "/sys/devices/system/cpu"
                             (lambda (d)
                               (and (string-prefix? "cpu" d)
                                    (string->number (substring d 3)))))
                    '())))
   string<?))

;; Low iff the first policy's max is pinned to its hardware minimum.
(define (low-power-now?)
  (let* ((policies (cpu-policies))
         (p (and (pair? policies) (car policies))))
    (and p
         (equal? (sysfs-read (string-append p "/scaling_max_freq"))
                 (sysfs-read (string-append p "/cpuinfo_min_freq"))))))

(define (set-mode! low?)
  ;; Cores back online first when restoring, offline last when lowering,
  ;; so their policy dirs exist while we write frequencies.
  (define online-files (cpu-online-files))
  (define (offline-half!)
    ;; Keep the first half (cpu0 + siblings), drop the rest.
    (let ((n (length online-files)))
      (for-each (lambda (f) (sysfs-write f "0"))
                (list-tail online-files (quotient n 2)))))
  (unless low?
    (for-each (lambda (f) (sysfs-write f "1")) online-files))
  (for-each
   (lambda (p)
     (sysfs-write (string-append p "/scaling_governor") "powersave")
     (sysfs-write (string-append p "/energy_performance_preference")
                  (if low? "power" "balance_performance"))
     (sysfs-write (string-append p "/scaling_max_freq")
                  (sysfs-read (string-append p (if low?
                                                   "/cpuinfo_min_freq"
                                                   "/cpuinfo_max_freq")))))
   (cpu-policies))
  ;; Turbo/boost: intel_pstate spells it no_turbo (1 = off), acpi-cpufreq
  ;; spells it boost (0 = off); only one of the two files exists.
  (sysfs-write "/sys/devices/system/cpu/intel_pstate/no_turbo"
               (if low? "1" "0"))
  (sysfs-write "/sys/devices/system/cpu/cpufreq/boost"
               (if low? "0" "1"))
  ;; Firmware-level profile (fans, package power limits) on ThinkPads.
  (sysfs-write "/sys/firmware/acpi/platform_profile"
               (if low? "low-power" "balanced"))
  (when low? (offline-half!)))

(let ((go-low? (not (low-power-now?))))
  (set-mode! go-low?)
  (format #t "Low power mode ~a (~a cores online, max ~a kHz).~%"
          (if go-low? "ON" "OFF")
          (+ 1 (length (filter (lambda (f) (equal? "1" (sysfs-read f)))
                               (cpu-online-files))))
          (sysfs-read "/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq")))
