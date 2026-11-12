#!/usr/bin/env guile
!#
;;; voice-dictate.scm --- System-wide push-to-talk dictation
;;;
;;; Toggle: first invocation records the mic with ffmpeg; second invocation
;;; stops, transcribes locally with whisper.cpp, and types the result into the
;;; focused window.  Fully local — no API key.
;;;
;;; Minde: Print V. Notifications use notify-send, clipboard wl-copy,
;;; and typing wtype.

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
(define log-file  (string-append runtime-dir "/voice-dictate.log"))

(define model-file
  (string-append home "/.local/share/whisper/ggml-small.bin"))

;; Follow the currently selected PipeWire/PulseAudio input on every host.
(define mic-source "default")

;; ── Helpers ────────────────────────────────────────────────────────────────
(define (notify summary . body)
  "Transient desktop notification (replaces id 9001), best-effort."
  (false-if-exception
   (apply system* "notify-send" "-r" "9001" "-t" "4000" summary body)))

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
  (unless (file-exists? model-file)
    (error "Whisper model missing" model-file))
  (let ((pid (primitive-fork)))
    (if (zero? pid)
        ;; Child: detach, silence output, become ffmpeg.
        (begin
          (setsid)
          (let ((log (open-fdes log-file (logior O_WRONLY O_CREAT O_TRUNC) #o600)))
            (dup2 log 1)
            (dup2 log 2)
            (close-fdes log))
          (execlp "ffmpeg" "ffmpeg" "-y"
                  "-f" "pulse" "-i" mic-source
                  "-ar" "16000" "-ac" "1"
                  wav-file))
        ;; Reap immediate failures: kill(0) alone would accept a zombie.
        (begin
          (usleep 350000)
          (unless (zero? (car (waitpid pid WNOHANG)))
            (remove-file* wav-file)
            (error "Microphone recording failed; see log" log-file))
          (call-with-output-file pid-file
            (lambda (p) (display pid p)))
          (notify "🎤 Recording…" "Print V again to transcribe")))))

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
    (unless (zero? (close-pipe port))
      (error "Whisper transcription failed" model-file))
    (clean-transcript out)))

(define (deliver text)
  "Put TEXT on the clipboard, then type it into the focused window."
  (let ((p (open-pipe* OPEN_WRITE "wl-copy")))
    (display text p)
    (close-pipe p))
  (system* "wtype" "--" text)
  (notify "✅ Eingefügt" text))

(define (stop-and-transcribe pid)
  (false-if-exception (kill pid SIGINT))   ; let ffmpeg finalize the WAV
  (remove-file* pid-file)
  (sleep 1)                                ; allow the file to flush
  (notify "✍ Transcribing…")
  (dynamic-wind
    (lambda () #t)
    (lambda ()
      (let ((text (transcribe)))
        (if (string=? text "")
            (notify "🔇 No speech detected")
            (deliver text))))
    (lambda () (remove-file* wav-file))))

;; ── Entry point ────────────────────────────────────────────────────────────
(define (main args)
  (let ((pid (read-pid)))
    (cond
     ((and pid (process-alive? pid)) (stop-and-transcribe pid))
     (pid
      (remove-file* pid-file)
      (remove-file* wav-file)
      (error "Recording stopped unexpectedly; see log" log-file))
     (else (start-recording)))))

(umask #o077)
(catch #t
  (lambda () (main (command-line)))
  (lambda (key . args)
    (let ((message (format #f "~s: ~s" key args)))
      (format (current-error-port) "voice-dictate: ~a~%" message)
      (notify "Dictation failed" message)
      (exit 1))))
