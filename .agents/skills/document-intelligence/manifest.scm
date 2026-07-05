(use-modules (guix profiles))

(specifications->manifest
 '("bash"
   "coreutils"
   "glib"
   "libxcb"
   "mesa"
   "python"
   "python-pip"
   "python-virtualenv"
   "nss-certs"))
