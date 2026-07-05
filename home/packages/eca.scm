;;; eca.scm --- ECA (Editor Code Assistant) Emacs client
;;;
;;; ECA is an editor-agnostic, autonomous AI coding agent.  It has two parts:
;;;
;;;   1. the *server* — a standalone program that runs the agent loop
;;;      (chat, tool-use, file edits, MCP).  It is a JVM program; we run it
;;;      with `openjdk' (added to the home profile in base-packages.scm) or let
;;;      eca-emacs download a native build.  See eca-conf.el for wiring.
;;;
;;;   2. the *client* — this Emacs package (`emacs-eca'), which talks to the
;;;      server over ECA's JSON protocol.
;;;
;;; This package pins eca-emacs directly because it is not available from the
;;; Guix channel used by this configuration.

(define-module (packages eca)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system emacs)
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs-build)   ; dash, s, f, compat
  #:use-module (gnu packages emacs-xyz))    ; markdown-mode

(define-public emacs-eca
  (package
    (name "emacs-eca")
    ;; Pinned to eca-emacs HEAD as of 2026-06-24.
    (version "0-1.f91296c")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/editor-code-assistant/eca-emacs/archive/"
                    "f91296cd8ddd1477700cc81c3edda0a45b1a6cd1.tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "05gk9f5d1faz43qp10xagwfq32xm6z98md4pzb8hmr1r0qbikw56"))))
    (build-system emacs-build-system)
    ;; Matches eca-emacs Package-Requires (sans the Emacs version bound).
    (propagated-inputs
     (list emacs-dash
           emacs-s
           emacs-f
           emacs-markdown-mode
           emacs-compat))
    (home-page "https://github.com/editor-code-assistant/eca-emacs")
    (synopsis "Emacs client for ECA, the Editor Code Assistant")
    (description
     "ECA (Editor Code Assistant) is an editor-agnostic AI coding agent that
runs an autonomous agent loop (chat, tool-use, file editing, MCP) in a
standalone server.  This package is the Emacs front-end that drives that
server over ECA's JSON protocol.")
    (license license:asl2.0)))
