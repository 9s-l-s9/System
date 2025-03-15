 (define-module (schemesh)
  #:use-module (guix packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages chez)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages base)
  #:use-module (gnu packages curl)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:))


(define-public schemesh
  (package
    (name "schemesh")
    (version "0.7.6")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/cosmos72/schemesh.git")
             (commit "748af547f02367f6fc0bb67bb10ad13e6f7fd890")))
       (file-name (git-file-name name version))
       (sha256 (base32 "1hp5ik9sfch0ycypjcvb2im26vwcnwmmzyrwhamgvi216qxsvvkk"))))
 (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((gcc (assoc-ref inputs "gcc"))
                   (chez (assoc-ref inputs "chez-scheme"))
                   (lz4 (assoc-ref inputs "lz4"))
                   (zlib (assoc-ref inputs "zlib"))
                   (ncurses (assoc-ref inputs "ncurses"))
                   (util-linux (assoc-ref inputs "util-linux")))

               ;; Set LDFLAGS to include all library paths
               (setenv "LDFLAGS" 
                      (string-append 
                       "-L" chez "/lib/csv10.1.0/ta6le " 
                       "-L" lz4 "/lib " 
                       "-L" zlib "/lib " 
                       "-L" ncurses "/lib " 
                       "-L" util-linux "/lib"))

               ;; Set LIBS directly to override Makefile's value
               (setenv "LIBS" 
                      (string-append 
                       chez "/lib/csv10.1.0/ta6le/kernel.o " 
                       "-lz -llz4 -lncurses -ldl -lm -lpthread"))

               ;; Set LIB_UUID to empty to avoid using it
               (setenv "LIB_UUID" "")

               ;; Run make with explicit variables
               (invoke "make" 
                       (string-append "CC=" gcc "/bin/gcc")
                       (string-append "CHEZ_SCHEME_DIR=" chez "/lib/csv10.1.0/ta6le")
                       "LIBS=$(CHEZ_SCHEME_KERNEL) -lz -llz4 -lncurses -ldl -lm -lpthread"))
             #t))
         (replace 'install
           (lambda* (#:key outputs inputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out"))
                   (gcc (assoc-ref inputs "gcc"))
                   (chez (assoc-ref inputs "chez-scheme")))
               (invoke "make" "install"
                       (string-append "CC=" gcc "/bin/gcc") 
                       (string-append "CHEZ_SCHEME_DIR=" chez "/lib/csv10.1.0/ta6le")
                       (string-append "DESTDIR=" out)
                       "prefix="))
             #t)))))
    (native-inputs
     (("gcc" ,gcc)
       ("make" ,gnu-make)))
    (inputs
     (("curl" ,curl)
       ("lz4" ,lz4)
       ("ncurses" ,ncurses)
       ("util-linux" ,util-linux)
       ("chez-scheme" ,chez-scheme)
       ("zlib" ,zlib)))
    (synopsis "A lightweight tool built with Chez Scheme")
    (description
     "Schemesh is built using Chez Scheme and several C libraries.
It compiles an executable, a test binary, and a shared library.
This package definition adapts the build and install phases to work properly
within the Guix environment by overriding the default installation directories.")
    (home-page "https://github.com/cosmos72/schemesh")
    (license license:gpl3+)))
schemesh
