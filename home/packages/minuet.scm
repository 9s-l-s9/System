;;; minuet.scm --- Minuet AI inline code completion for Emacs
;;;
;;; Minuet is a vendor-agnostic "Copilot alternative": ghost-text / popup
;;; completion as you type, backed by Claude, OpenAI, Gemini, Ollama,
;;; llama.cpp, Codestral, etc.  Here it reuses your ANTHROPIC_API_KEY and
;;; feeds completions through the corfu/cape stack you already run.

(define-module (packages minuet)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system emacs)
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs-build)   ; dash
  #:use-module (gnu packages emacs-xyz))    ; plz

(define-public emacs-minuet
  (package
    (name "emacs-minuet")
    ;; Pinned to minuet-ai.el HEAD as of 2026-06-24.
    (version "0-1.13fb314")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/milanglacier/minuet-ai.el/archive/"
                    "13fb314a795951b9190c53c59ef281abf7a2cb4f.tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "16r980ipbdql21p8vx41mkg75ygwjxabfz811b705kbf5b11dr8d"))))
    (build-system emacs-build-system)
    ;; Upstream test suite isn't meant to run in the isolated build sandbox.
    (arguments (list #:tests? #f))
    ;; Matches minuet Package-Requires (sans the Emacs version bound).
    (propagated-inputs
     (list emacs-plz
           emacs-dash))
    (home-page "https://github.com/milanglacier/minuet-ai.el")
    (synopsis "AI-powered inline code completion for Emacs")
    (description
     "Minuet brings vendor-agnostic AI code completion to Emacs: as-you-type
ghost text or on-demand popup suggestions, backed by any of several LLM
providers (Claude, OpenAI, Gemini, Ollama, llama.cpp, Codestral).  It
integrates with the completion-at-point / corfu stack.")
    (license license:gpl3+)))
