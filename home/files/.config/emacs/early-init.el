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

(add-hook 'emacs-startup-hook
          (lambda ()
            ;; 100 MB: fewer, batched collections. 8 MB caused visible
            ;; micro-pauses while typing under eglot/corfu churn.
            (setq gc-cons-threshold (* 1000 1000 100)
                  gc-cons-percentage 0.1
                  file-name-handler-alist prot-emacs--file-name-handler-alist
                  vc-handled-backends prot-emacs--vc-handled-backends)))
