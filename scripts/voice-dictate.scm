#!/usr/bin/env guile
!#
;;; voice-dictate.scm --- System-wide push-to-talk dictation for StumpWM
;;;
;;; Toggle: first invocation records the mic with ffmpeg; second invocation
;;; stops, transcribes locally with whisper.cpp, and types the result into the
;;; focused window (clipboard fallback via xsel).  Fully local — no API key.
;;;
;;; Bound in home/services/stumpwm.scm as `voice-dictate' (Print w).

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 textual-ports)
             (srfi srfi-13))

;; ── Configuration ──────────────────────────────────────────────────────────
(define home (getenv "HOME"))

(define runtime-dir
  (or (getenv "XDG_RUNTIME_DIR") "/tmp"))

(define pid-file  (string-append runtime-dir "/voice-dictate.pid"))
(define wav-file  (string-append runtime-dir "/voice-dictate.wav"))

(define model-file
  (string-append home "/.local/share/whisper/ggml-small.bin"))

;; Mic source from `pactl list sources short' (T450s built-in analog input).
(define mic-source "alsa_input.pci-0000_00_1b.0.analog-stereo")

;; ── Helpers ────────────────────────────────────────────────────────────────
(define (notify summary . body)
  "Transient desktop notification (replaces id 9001), best-effort."
  (false-if-exception
   (apply system* "dunstify" "-r" "9001" "-t" "4000" summary body)))

(define (process-alive? pid)
  "True if PID exists (signal 0 probe)."
  (false-if-exception (begin (kill pid 0) #t)))

(define (read-pid)
  (and (file-exists? pid-file)
       (let* ((port (open-input-file pid-file))
              (str  (string-trim-both (get-string-all port))))
         (close-port port)
         (and (string->number str) (string->number str)))))

(define (remove-file* path)
  (when (file-exists? path) (delete-file path)))

;; ── Recording ──────────────────────────────────────────────────────────────
(define (start-recording)
  (let ((pid (primitive-fork)))
    (if (zero? pid)
        ;; Child: detach, silence output, become ffmpeg.
        (begin
          (setsid)
          (let ((null (open-fdes "/dev/null" O_WRONLY)))
            (dup2 null 1)
            (dup2 null 2))
          (execlp "ffmpeg" "ffmpeg" "-y"
                  "-f" "pulse" "-i" mic-source
                  "-ar" "16000" "-ac" "1"
                  wav-file))
        ;; Parent: record the child's PID and notify.
        (begin
          (call-with-output-file pid-file
            (lambda (p) (display pid p)))
          (notify "🎤 Recording…" "Print w again to transcribe")))))

;; ── Transcription ──────────────────────────────────────────────────────────
(define (clean-transcript text)
  "Trim whisper output and drop its no-speech marker."
  (let ((t (string-trim-both text)))
    (if (or (string=? t "") (string-contains t "[BLANK_AUDIO]"))
        ""
        t)))

(define (transcribe)
  (let* ((port (open-pipe* OPEN_READ "whisper-cli"
                           "--model" model-file
                           "--language" "auto"
                           "--no-timestamps"
                           "--threads" "4"
                           "--file" wav-file))
         (out (let loop ((acc '()))
                (let ((line (read-line port)))
                  (if (eof-object? line)
                      (string-join (reverse acc) " ")
                      (loop (cons (string-trim-both line) acc)))))))
    (close-pipe port)
    (clean-transcript out)))

(define (deliver text)
  "Put TEXT on the clipboard, then type it into the focused window."
  (let ((p (open-pipe* OPEN_WRITE "xsel" "--clipboard" "--input")))
    (display text p)
    (close-pipe p))
  (system* "xdotool" "type" "--clearmodifiers" "--" text)
  (notify "✅ Eingefügt" text))

(define (stop-and-transcribe pid)
  (false-if-exception (kill pid SIGINT))   ; let ffmpeg finalize the WAV
  (remove-file* pid-file)
  (sleep 1)                                ; allow the file to flush
  (notify "✍ Transcribing…")
  (let ((text (transcribe)))
    (remove-file* wav-file)
    (if (string=? text "")
        (notify "🔇 No speech detected")
        (deliver text))))

;; ── Entry point ────────────────────────────────────────────────────────────
(define (main args)
  (let ((pid (read-pid)))
    (if (and pid (process-alive? pid))
        (stop-and-transcribe pid)
        (begin
          (remove-file* pid-file)          ; clear any stale lock
          (start-recording)))))

(main (command-line))
