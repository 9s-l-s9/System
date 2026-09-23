;;; early-init.el --- -*- lexical-binding: t -*-
;; Based on config by prot https://protesilaos.com/


;; Basic UI

(setq frame-resize-pixelwise t
      frame-inhibit-implied-resize t
      frame-title-format '("%b")
      ring-bell-function 'ignore
      use-dialog-box nil
      use-file-dialog nil
      use-short-answers t
      inhibit-splash-screen t
      inhibit-startup-screen t
      inhibit-x-resources t
      inhibit-startup-buffer-menu t)

;; PGTK otherwise draws a client-side title bar above the editor.  The
;; compositor owns window framing, so ask GTK for a borderless surface.
(add-to-list 'default-frame-alist '(undecorated . t))

;; Must be a literal in early-init for Emacs to honor it.
(setq inhibit-startup-echo-area-message "samuel")

;; Relocate runtime files out of ~/.config/emacs/ early, before recentf,
;; savehist, url, etc. capture the original `user-emacs-directory'.
(setq user-emacs-directory "~/.cache/emacs/")

;; Guix wires package autoloads through site-start.el, so package.el is not
;; needed at startup.  Leaving it on makes it scan every site-lisp dir and
;; log "Unable to activate package" for Guix version strings it can't parse.
(setq package-enable-at-startup nil)
(setq url-history-file (expand-file-name "url/history" user-emacs-directory))

;; I do not use those graphical elements by default, but I do enable
;; them from time-to-time for testing purposes or to demonstrate
;; something.  NEVER tell a beginner to disable any of these.  They
;; are helpful.
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(setq fast-but-imprecise-scrolling 't)

;; Name default frame
(add-hook 'after-init-hook (lambda () (set-frame-name "home")))


;; start-up time tweaks

;; Temporarily increase the garbage collection threshold.  These
;; changes help shave off about half a second of startup time.  The
;; `most-positive-fixnum' is DANGEROUS AS A PERMANENT VALUE.  See the
;; `emacs-startup-hook' a few lines below for what I actually use.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.5)

;; Same idea as above for the `file-name-handler-alist' and the
;; `vc-handled-backends' with regard to startup speed optimisation.
;; Here I am storing the default value with the intent of restoring it
;; via the `emacs-startup-hook'.
(defvar prot-emacs--file-name-handler-alist file-name-handler-alist)
(defvar prot-emacs--vc-handled-backends vc-handled-backends)

(setq file-name-handler-alist nil
      vc-handled-backends nil)

;; Never load a stale .elc over a newer .el (e.g. the VALSI working tree,
;; which sits on `load-path' and is edited in place).
(setq load-prefer-newer t)

;; Native compilation.  Guix ships Emacs Lisp packages byte-compiled only
;; and disables just-in-time native compilation, so without this every
;; package -- Emacs' own Lisp aside -- runs as byte-code.  Turning JIT on
;; makes Emacs compile each library to native code the first time it is
;; loaded and reuse the result from `~/.config/emacs/eln-cache' forever
;; after; allocation-heavy Lisp typically runs several times faster.
;;
;; This needs a C driver for libgccjit, which is why `gcc-toolchain' is in
;; the home profile.  Without it `native-comp-available-p' still reports t
;; while every compilation fails silently.
;;
;; Cost: a one-time burst of background compilation after this lands, and
;; again after every Emacs version upgrade (the cache is keyed by ABI, so
;; an upgrade invalidates all of it).  Two jobs keeps that burst off the
;; other two cores of this machine.
(when (and (fboundp 'native-comp-available-p) (native-comp-available-p))
  (setq native-comp-jit-compilation t
        native-comp-async-jobs-number 2
        native-comp-async-report-warnings-errors 'silent))

(add-hook 'emacs-startup-hook
          (lambda ()
            ;; 100 MB: fewer, batched collections. 8 MB caused visible
            ;; micro-pauses while typing under eglot/corfu churn.
            (setq gc-cons-threshold (* 1000 1000 100)
                  gc-cons-percentage 0.1
                  file-name-handler-alist prot-emacs--file-name-handler-alist
                  vc-handled-backends prot-emacs--vc-handled-backends)))
