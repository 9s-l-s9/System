;; Dependencies for the upstream AnyLogic Linux distribution, including the
;; native libraries loaded from SWT/JNI jars and the simulation browser.
(define-module (manifests anylogic-runtime)
  #:use-module (guix profiles)
  #:use-module (gnu packages)
  #:use-module (gnu packages gcc))

(packages->manifest
 (cons (list gcc "lib")
       (map specification->package
            '("glibc" "gtk+" "nss" "nspr"
              "alsa-lib" "libxtst" "libxscrnsaver" "libx11"
              "libxrender" "libxi" "libxext" "libxt" "libxcomposite"
              "libxdamage" "libxfixes" "libxrandr" "libxcb"
              "libxkbcommon" "libdrm" "dbus" "cups"
              "fontconfig" "freetype" "zlib" "mesa" "eudev"
              "openssl" "expat" "patchelf" "unzip" "nss-certs"
              "adwaita-icon-theme" "hicolor-icon-theme"
              "gsettings-desktop-schemas" "shared-mime-info"))))
