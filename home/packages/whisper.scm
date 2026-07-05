;;; whisper.scm --- whisper.el: local speech-to-text for Emacs
;;;
;;; whisper.el records audio (via ffmpeg) and transcribes it locally with
;;; whisper.cpp — no cloud, no API key, no subscription.  We point it at the
;;; `whisper-cpp' binary already in the profile (see base-packages.scm) instead
;;; of letting it compile its own copy.
;;;
(define-module (packages whisper)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system emacs)
  #:use-module (gnu packages))

(define-public emacs-whisper
  (package
    (name "emacs-whisper")
    ;; Pinned to whisper.el HEAD as of 2026-06-24.
    (version "0-1.fd9bf57")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/natrys/whisper.el/archive/"
                    "fd9bf5787a99dd31a4bdf54d2bd9821aacf84e93.tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1fsdf5a4wl71fgmxhmbzaq051lbkv96arxjqvimdm05jhb8lc2s3"))))
    (build-system emacs-build-system)
    (arguments (list #:tests? #f))
    ;; whisper.el has no Elisp package dependencies (just Emacs itself); the
    ;; runtime tools (whisper-cpp, ffmpeg) come from the profile, not here.
    (home-page "https://github.com/natrys/whisper.el")
    (synopsis "Speech-to-text input for Emacs using whisper.cpp")
    (description
     "whisper.el provides local, offline speech-to-text in Emacs.  It records
audio with ffmpeg and transcribes it with whisper.cpp, inserting the result
into the current buffer — usable for dictation or for speaking prompts to AI
assistants.")
    (license license:gpl3+)))
