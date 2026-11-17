(define-module (packages gamescope)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system meson)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages image)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages hardware)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages python)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages xml))

;; Gamescope, Valve's nested micro-compositor, is not in Guix.  It is used to
;; run Europa Universalis IV at 1706x960 with UI scale 1.0 and upscale it to
;; the monitor's native 2560x1440 with FSR, which keeps the bitmap UI sharper
;; than the game's own UI scale 1.5 (see services/steam.scm).

(define glm-source
  ;; Revision pinned by subprojects/glm.wrap of gamescope 3.16.31.
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/g-truc/glm")
          (commit "0af55ccecd98d4e5a8d1fad7de25ba429d60e863")))
    (file-name "glm-gamescope-checkout")
    (sha256
     (base32 "0890rvv3czi3nqj11dc2m3wcdfv0dm0nr63wfcpfikk9sk6b4w8s"))))

(define stb-source
  ;; Revision pinned by subprojects/stb.wrap of gamescope 3.16.31.
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/nothings/stb")
          (commit "5736b15f7ea0ffb08dd38af21067c314d6a3aae9")))
    (file-name "stb-gamescope-checkout")
    (sha256
     (base32 "1pwgj5283qdv7b6hnli746dxnj5jg89qc7zwm9mi6v7paiv14q5k"))))

(define-public gamescope
  (package
    (name "gamescope")
    (version "3.16.31")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/ValveSoftware/gamescope")
             (commit version)
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0hrxpw59iiz325kvygmd3ffygjiqdh16hnv4pr6sq1na4zy9y84q"))))
    (build-system meson-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list "-Dforce_fallback_for=libliftoff,vkroots,wlroots,libdisplay-info"
              "-Denable_openvr_support=false"
              "-Denable_tests=false"
              "-Denable_zenity=false"
              "-Dbenchmark=disabled"
              "-Dpipewire=disabled"
              "-Davif_screenshots=disabled"
              "-Dinput_emulation=disabled"
              "-Ddrm_backend=enabled"
              "-Dsdl2_backend=enabled")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'vendor-wrap-subprojects
            (lambda _
              ;; Meson would download glm and stb; use pinned sources instead.
              (delete-file "subprojects/glm.wrap")
              (delete-file "subprojects/stb.wrap")
              (copy-recursively #$glm-source "subprojects/glm")
              (copy-recursively #$stb-source "subprojects/stb")
              (copy-file "subprojects/packagefiles/glm/meson.build"
                         "subprojects/glm/meson.build")
              (copy-file "subprojects/packagefiles/stb/meson.build"
                         "subprojects/stb/meson.build")))
          (add-after 'unpack 'fix-version-tag
            (lambda _
              ;; No .git in the build tree; hard-code the release tag.
              (substitute* "src/meson.build"
                (("\\['git', 'describe', '--always', '--tags', '--dirty=\\+'\\]")
                 (string-append "['echo', '" #$version "']")))))
          (add-after 'unpack 'allow-unmapped-x11-socket-dir
            (lambda _
              ;; Inside nonguix's Steam container (a user namespace) the
              ;; host's root-owned /tmp/.X11-unix shows up as owned by the
              ;; overflow uid, so wlroots refused to start Xwayland.  The
              ;; sticky-bit check below still guards against other users.
              (substitute* "subprojects/wlroots/xwayland/sockets.c"
                (("if \\(!\\(\\(buf\\.st_uid == 0\\) \\|\\| \\(buf\\.st_uid == getuid\\(\\)\\)\\)\\) \\{")
                 "if (0) {"))))
          (add-after 'unpack 'use-absolute-paths
            (lambda* (#:key inputs #:allow-other-keys)
              ;; dlopen("libvulkan.so.1") has no RUNPATH to search on Guix,
              ;; and the reaper helper is looked up in PATH.
              (substitute* "src/rendervulkan.cpp"
                (("dlopen\\( \"libvulkan\\.so\\.1\"")
                 (string-append "dlopen( \""
                                (search-input-file inputs "lib/libvulkan.so.1")
                                "\"")))
              (substitute* "src/Utils/Process.cpp"
                (("\\(char \\*\\)\"gamescopereaper\"")
                 (string-append "(char *)\"" #$output
                                "/bin/gamescopereaper\""))))))))
    (native-inputs
     (list pkg-config glslang wayland python cmake))
    (inputs
     (list eudev
           hwdata
           libcap
           libdecor
           libdrm
           libinput
           libseat
           libx11
           libxcomposite
           libxcursor
           libxdamage
           libxext
           libxfixes
           libxi
           libxkbcommon
           libxmu
           libxrender
           libxres
           libxtst
           libxxf86vm
           libxcb
           luajit
           pixman
           sdl2
           vulkan-headers
           vulkan-loader
           wayland
           wayland-protocols
           xcb-util-errors
           xcb-util-renderutil
           xcb-util-wm
           xorg-server-xwayland))
    (home-page "https://github.com/ValveSoftware/gamescope")
    (synopsis "SteamOS session micro-compositor")
    (description
     "Gamescope is a micro-compositor that runs games in a nested session and
can upscale them, e.g. with AMD FidelityFX Super Resolution (FSR).")
    (license license:bsd-2)))
