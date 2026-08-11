(define-module (packages anki)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages kerberos)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (nonguix build-system binary))

;; Nonguix currently packages Anki's obsolete 25.09 network installer.  This
;; package instead installs the complete upstream bundle introduced in 26.05:
;; Python, Qt, and Anki are fixed Guix store inputs, with no second installation
;; under $HOME and no network/bootstrap step on first launch.
(define-public anki-bin
  (package
    (name "anki-bin")
    (version "26.08.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ankitects/anki/releases/download/"
             version "/anki-" version "-linux-x86_64.tar.zst"))
       (file-name (string-append name "-" version ".tar.zst"))
       (sha256
        (base32 "1px7wiifiia60z7z23ns4ckqnf741vz1117k7wbyqqg3n1l5ly48"))))
    (supported-systems '("x86_64-linux"))
    (build-system binary-build-system)
    (arguments
     (list
      ;; The archive is an already-stripped, self-contained Briefcase bundle.
      #:strip-binaries? #f
      ;; Some optional Qt plugins reference libraries that Anki never loads.
      ;; The launch smoke test below is more useful than rejecting the whole
      ;; bundle for an unused SQL, sensor, or text-to-speech plugin.
      #:validate-runpath? #f
      ;; The bundle is patched after installation below.  A patchelf plan is
      ;; computed before the source is unpacked, so it cannot discover this
      ;; archive's nested ELF objects reliably.
      #:patchelf-plan ''()
      #:install-plan ''(("." "lib/anki"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patch-elf-files
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((bundle (string-append #$output "/lib/anki"))
                     (interpreter
                      (car (find-files (assoc-ref inputs "libc")
                                       "ld-linux.*\\.so")))
                     (library-inputs
                      '("alsa-lib"
                        "brotli"
                        "dbus"
                        "eudev"
                        "expat"
                        "fontconfig-minimal"
                        "freetype"
                        "gcc:lib"
                        "glib"
                        "libc"
                        "libdrm"
                        "libx11"
                        "libxcb"
                        "libxcomposite"
                        "libxcursor"
                        "libxdamage"
                        "libxext"
                        "libxfixes"
                        "libxi"
                        "libxinerama"
                        "libxkbcommon"
                        "libxkbfile"
                        "libxrandr"
                        "libxrender"
                        "libxshmfence"
                        "libxtst"
                        "mesa"
                        "mit-krb5"
                        "nspr"
                        "openssl"
                        "wayland"
                        "xcb-util"
                        "xcb-util-cursor"
                        "xcb-util-image"
                        "xcb-util-keysyms"
                        "xcb-util-renderutil"
                        "xcb-util-wm"
                        "zlib"
                        "zstd:lib"))
                     (rpath
                      (string-join
                       (append
                        (map (lambda (name)
                               (string-append (assoc-ref inputs name) "/lib"))
                             library-inputs)
                        (list (string-append (assoc-ref inputs "nss")
                                             "/lib/nss")
                              bundle
                              (string-append bundle "/python/lib")
                              (string-append bundle
                                             "/app_packages/PyQt6/Qt6/lib")))
                       ":")))
                ;; Keep each object's upstream $ORIGIN entries, which are
                ;; needed by bundled Python wheels, and append Guix store
                ;; locations for external libraries.
                (for-each
                 (lambda (file)
                   (make-file-writable file)
                   (unless (string-contains file ".so")
                     (invoke "patchelf" "--set-interpreter" interpreter file))
                   (invoke "patchelf" "--add-rpath" rpath file))
                 (find-files bundle
                             (lambda (file stat)
                               (elf-file? file)))))))
          (add-after 'patch-elf-files 'install-desktop-integration
            (lambda _
              (let ((bundle (string-append #$output "/lib/anki")))
                (for-each mkdir-p
                          (list (string-append #$output "/bin")
                                (string-append #$output "/share/applications")
                                (string-append
                                 #$output
                                 "/share/icons/hicolor/128x128/apps")
                                (string-append #$output "/share/man/man1")
                                (string-append #$output "/share/mime/packages")
                                (string-append #$output "/share/pixmaps")))
                (symlink (string-append bundle "/anki")
                         (string-append #$output "/bin/anki"))
                (copy-file (string-append bundle "/anki.desktop")
                           (string-append #$output "/share/applications/anki.desktop"))
                (copy-file (string-append bundle "/anki.png")
                           (string-append
                            #$output
                            "/share/icons/hicolor/128x128/apps/anki.png"))
                (copy-file (string-append bundle "/anki.png")
                           (string-append #$output "/share/pixmaps/anki.png"))
                (copy-file (string-append bundle "/anki.1")
                           (string-append #$output "/share/man/man1/anki.1"))
                (copy-file (string-append bundle "/anki.xml")
                           (string-append #$output "/share/mime/packages/anki.xml")))))
          (add-after 'install-desktop-integration 'wrap-runtime-environment
            (lambda _
              (let* ((bundle (string-append #$output "/lib/anki"))
                     (qt (string-append bundle
                                        "/app_packages/PyQt6/Qt6")))
                (wrap-program (string-append bundle "/anki")
                  `("PATH" prefix
                    (,(string-append #$(this-package-input
                                        "flatpak-xdg-utils")
                                     "/bin")))
                  `("LIBGL_DRIVERS_PATH" prefix
                    (,(string-append #$(this-package-input "mesa")
                                     "/lib/dri")))
                  ;; The surrounding Guix session exports Qt 6.9 paths.  Anki
                  ;; ships Qt 6.11, and loading plugins across that ABI boundary
                  ;; causes a startup crash.
                  `("QT_PLUGIN_PATH" = (,(string-append qt "/plugins")))
                  `("QML_IMPORT_PATH" = (,(string-append qt "/qml")))
                  `("QML2_IMPORT_PATH" = (,(string-append qt "/qml")))
                  ;; XWayland is Anki's conservative path; native Wayland still
                  ;; has upstream focus and window-decoration issues.
                  `("QT_QPA_PLATFORM" = ("xcb")))))))))
    (native-inputs (list zstd))
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("bash-minimal" ,bash-minimal)
       ("brotli" ,brotli)
       ("dbus" ,dbus)
       ("eudev" ,eudev)
       ("expat" ,expat)
       ("flatpak-xdg-utils" ,flatpak-xdg-utils)
       ("fontconfig-minimal" ,fontconfig)
       ("freetype" ,freetype)
       ("gcc:lib" ,gcc "lib")
       ("glib" ,glib)
       ("libdrm" ,libdrm)
       ("libx11" ,libx11)
       ("libxcb" ,libxcb)
       ("libxcomposite" ,libxcomposite)
       ("libxcursor" ,libxcursor)
       ("libxdamage" ,libxdamage)
       ("libxext" ,libxext)
       ("libxfixes" ,libxfixes)
       ("libxi" ,libxi)
       ("libxinerama" ,libxinerama)
       ("libxkbcommon" ,libxkbcommon)
       ("libxkbfile" ,libxkbfile)
       ("libxrandr" ,libxrandr)
       ("libxrender" ,libxrender)
       ("libxshmfence" ,libxshmfence)
       ("libxtst" ,libxtst)
       ("mesa" ,mesa)
       ("mit-krb5" ,mit-krb5)
       ("nspr" ,nspr)
       ("nss" ,nss)
       ("openssl" ,openssl)
       ("wayland" ,wayland)
       ("xcb-util" ,xcb-util)
       ("xcb-util-cursor" ,xcb-util-cursor)
       ("xcb-util-image" ,xcb-util-image)
       ("xcb-util-keysyms" ,xcb-util-keysyms)
       ("xcb-util-renderutil" ,xcb-util-renderutil)
       ("xcb-util-wm" ,xcb-util-wm)
       ("zlib" ,zlib)
       ("zstd:lib" ,zstd "lib")))
    (home-page "https://apps.ankiweb.net/")
    (synopsis "Spaced-repetition flashcard program")
    (description
     "Anki is a flashcard program that schedules reviews according to how well
you remember each card.  This package adapts Anki's complete upstream Linux
bundle for Guix, retaining the bundled Python and Qt versions tested by Anki's
developers while making all external runtime dependencies explicit.")
    (license license:agpl3+)))

;; Make `guix build/install -f this-file.scm` work directly.
anki-bin
