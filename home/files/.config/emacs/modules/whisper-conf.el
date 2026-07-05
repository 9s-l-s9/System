;;; whisper-conf.el --- Local speech-to-text via whisper.cpp -*- lexical-binding: t -*-
;;; Commentary:
;; Push-to-talk dictation into any buffer, transcribed locally by whisper.cpp.
;; Point it at a gptel or ECA prompt and it becomes "voice commands" for the
;; agent.  No cloud, no API key, no subscription.
;;
;; Requires (from the Guix profile): whisper-cpp (provides `whisper-cli'),
;; ffmpeg, and a downloaded ggml model.  Download the multilingual small model
;; once:
;;
;;   mkdir -p ~/.local/share/whisper
;;   curl -L -o ~/.local/share/whisper/ggml-small.bin \
;;     https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
;;
;; Guarded so a missing package/model never breaks startup.
;;; Code:

(defvar sls-whisper-model-file
  (expand-file-name "~/.local/share/whisper/ggml-small.bin")
  "Path to the ggml whisper model used for transcription.")

(when (require 'whisper nil t)

  ;; Recording (ffmpeg from PulseAudio default source).
  ;; Don't let whisper.el clone + cmake-build its own whisper.cpp; we supply
  ;; the binary from the Guix profile via the `whisper-command' override below.
  (setq whisper-install-whispercpp nil)

  (setq whisper--ffmpeg-input-format "pulse"
        ;; Mic source from `pactl list sources short' (T450s built-in analog in).
        whisper--ffmpeg-input-device "alsa_input.pci-0000_00_1b.0.analog-stereo"
        whisper-language "auto"          ; multilingual auto-detect
        whisper-translate nil            ; transcribe verbatim, don't translate
        whisper-use-threads 4)

  ;; Use the Guix whisper-cli + our model instead of a self-built copy.
  ;; whisper.el calls `whisper-command' to build the transcription invocation.
  ;; We override it to use the binary from the profile.  If your whisper.el
  ;; version expects a different signature, this is the one spot to adjust.
  (defun whisper-command (input-file)
    "Transcribe INPUT-FILE with the profile's whisper-cli and our model."
    (list (or (executable-find "whisper-cli")
              (executable-find "whisper-cpp")
              "whisper-cli")
          "--model"        sls-whisper-model-file
          "--language"     whisper-language
          "--no-timestamps"
          "--threads"      (number-to-string whisper-use-threads)
          "--file"         input-file))

  ;; Keybinding lives in keybindings-conf.el (meow leader: SPC w).
  ;; `whisper-run' toggles: first call records, second stops + inserts text.
  )

(provide 'whisper-conf)
;;; whisper-conf.el ends here
