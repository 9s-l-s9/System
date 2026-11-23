#!/usr/bin/env -S guile --no-auto-compile -s
!#
;;; Launch the official AnyLogic bundle with its dedicated Guix runtime.
(use-modules (ice-9 format) (srfi srfi-13))

(define state (string-append (getenv "HOME") "/.local/share/anylogic"))
(define runtime (string-append state "/runtime"))
(define bundle (string-append (getenv "HOME") "/.local/opt/anylogic-8.9.10"))

(unless (file-exists? (string-append bundle "/anylogic"))
  (format (current-error-port) "AnyLogic is not installed in ~a~%" bundle)
  (exit 1))

(define (prepend name value)
  (setenv name (string-append value
                             (if (getenv name)
                                 (string-append ":" (getenv name)) ""))))

;; SWT and licensing libraries unpacked from jars do not have Guix RPATHs.
(prepend "LD_LIBRARY_PATH"
         (string-append runtime "/lib:" runtime "/lib/nss:"
                        bundle "/natives/linux-amd64"))
(prepend "PATH" (string-append runtime "/bin"))
(prepend "XDG_DATA_DIRS" (string-append runtime "/share"))
(setenv "GSETTINGS_SCHEMA_DIR" (string-append runtime "/share/glib-2.0/schemas"))
(prepend "GUIX_GTK3_PATH" (string-append runtime "/lib/gtk-3.0"))
(prepend "GUIX_GDK_PIXBUF_MODULE_FILES"
         (string-append runtime "/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"))
(setenv "SSL_CERT_FILE" (string-append runtime "/etc/ssl/certs/ca-certificates.crt"))
(setenv "SSL_CERT_DIR" (string-append runtime "/etc/ssl/certs"))
(setenv "SWT_GTK3" "1")
(setenv "GDK_BACKEND" "x11")

;; The desktop GTK configuration (Breeze colors.css, dark preference, icon
;; theme missing from this runtime) mixes with AnyLogic's light custom
;; widgets: combo fields turn into unreadable white boxes. Give SWT a private
;; GTK config with the built-in light Adwaita theme instead.
(define gtk-config (string-append state "/config"))
(define (write-file name content)
  (call-with-output-file name (lambda (port) (display content port))))
(let ((dir (string-append gtk-config "/gtk-3.0")))
  (system* "mkdir" "-p" dir)
  (write-file (string-append dir "/settings.ini")
              (string-append "[Settings]\n"
                             "gtk-theme-name=Adwaita\n"
                             "gtk-application-prefer-dark-theme=false\n"
                             "gtk-icon-theme-name=Adwaita\n"
                             "gtk-font-name=Noto Sans 11\n"
                             "gtk-key-theme-name=Default\n"
                             "gtk-modules=\n"))
  ;; Keep fontconfig user settings visible under the changed config home.
  (let ((fonts (string-append gtk-config "/fontconfig"))
        (real (string-append (getenv "HOME") "/.config/fontconfig")))
    (when (and (file-exists? real) (not (file-exists? fonts)))
      (symlink real fonts))))
(setenv "XDG_CONFIG_HOME" gtk-config)
(setenv "GTK_THEME" "Adwaita")
(setenv "GTK_OVERLAY_SCROLLING" "0")
(unsetenv "GTK_MODULES")
;; JogAmp's jar cache probes executable directories using #!/bin/true,
;; absent on Guix. The installer extracts its native libraries ahead of time.
;; Apply to child JVMs too, including the separate 3D-rendering server.
(setenv "JAVA_TOOL_OPTIONS"
        (string-append (or (getenv "JAVA_TOOL_OPTIONS") "")
                       " -Djogamp.gluegen.UseTempJarCache=false"))
(chdir bundle)
(define executable (string-append bundle "/anylogic"))
;; Equinox locates its companion library relative to argv[0]. A bare
;; "anylogic" would resolve back to this launcher on PATH.
(apply execl executable executable (cdr (command-line)))
