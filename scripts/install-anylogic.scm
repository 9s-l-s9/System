#!/usr/bin/env -S guix repl -q --
!#
;;; Install AnyLogic PLE 8.9.10 from the official downloaded Linux installer.
;;; Usage: guix repl -- scripts/install-anylogic.scm /path/to/installer.bin
;;; The proprietary AnyLogic license applies; see the installer header.
(use-modules ((guix build utils) #:hide (delete))
             ((guix build syscalls) #:select (mkdtemp!))
             (ice-9 binary-ports)
             (ice-9 popen)
             (ice-9 textual-ports)
             (ice-9 format)
             (srfi srfi-1)
             (srfi srfi-13))

(define repository (dirname (dirname (canonicalize-path (current-filename)))))
(define version "8.9.10")
(define expected-hash "155wxlbkc1r0w7xdl654mlw3p51qrw13z56dyfw8x3dp7rn0cnxz")
(define state (string-append (getenv "HOME") "/.local/share/anylogic"))
(define runtime (string-append state "/runtime"))
(define destination (string-append (getenv "HOME") "/.local/opt/anylogic-" version))

(define (capture . command)
  (let* ((port (apply open-pipe* OPEN_READ command))
         (result (get-string-all port))
         (status (close-pipe port)))
    (unless (zero? status) (error "Command failed" command))
    (string-trim-both result)))

(unless (= (length (command-line)) 2)
  (error "Pass the downloaded anylogic-ple-8.9.10.linux.x86_64.tgz.bin"))
(define installer (canonicalize-path (cadr (command-line))))
(unless (string=? (capture "guix" "hash" installer) expected-hash)
  (error "Installer SHA256 does not match the pinned official download"))

(mkdir-p state)
(invoke "guix" "package" "--no-grafts" "-p" runtime "-m"
        (string-append repository "/home/manifests/anylogic-runtime.scm"))

(unless (file-exists? destination)
  (let ((stage (mkdtemp! (string-append state "/unpack.XXXXXX"))))
    ;; The upstream installer resets PATH to /usr/bin:/bin and rewrites the
    ;; workspace. Extract its payload without modifying an existing workspace.
    (call-with-input-file installer
      (lambda (input)
        (seek input 61066 SEEK_SET)
        (call-with-output-file (string-append stage "/payload.tar.gz")
          (lambda (output) (dump-port input output)))))
    (invoke "tar" "xzf" (string-append stage "/payload.tar.gz") "-C" stage)
    (mkdir-p (dirname destination))
    (rename-file (string-append stage "/anylogic") destination)
    (delete-file-recursively stage)))

;; JogAmp cannot use its temp-jar cache on Guix: its executable-directory
;; probe hardcodes /bin/true. Install the bundled JNI libraries explicitly.
(for-each
 (lambda (archive)
   (invoke (string-append runtime "/bin/unzip") "-o" archive
           "natives/linux-amd64/*" "-d" destination))
 (find-files (string-append destination "/plugins") "^com\\.anylogic\\.cef-.*-all\\.jar$"))

(define patchelf (string-append runtime "/bin/patchelf"))
(define interpreter
  (string-append runtime "/lib/ld-linux-x86-64.so.2"))
(define libraries (string-append runtime "/lib:" runtime "/lib/nss"))
(for-each
 (lambda (file)
   (let* ((rpath (capture patchelf "--print-rpath" file))
          (paths (delete-duplicates
                  (append (string-split rpath #\:)
                          (string-split libraries #\:)))))
     (let ((updated (string-join (delete "" paths) ":")))
       (unless (string=? rpath updated)
         (invoke patchelf "--set-rpath" updated file))))
   ;; Only executable ELF files have PT_INTERP; shared libraries do not.
   (let* ((port (open-pipe* OPEN_READ patchelf "--print-interpreter" file))
          (value (get-string-all port))
          (status (close-pipe port)))
     (when (and (zero? status)
                (not (string=? (string-trim-both value) interpreter)))
       (invoke patchelf "--set-interpreter" interpreter file))))
 (find-files destination (lambda (file stat) (elf-file? file))))

(let* ((bin (string-append (getenv "HOME") "/.local/bin"))
       (launcher (string-append bin "/anylogic"))
       (applications (string-append (getenv "HOME") "/.local/share/applications")))
  (mkdir-p bin)
  (mkdir-p applications)
  (copy-file (string-append repository "/scripts/anylogic.scm") launcher)
  (chmod launcher #o755)
  (call-with-output-file (string-append applications "/anylogic.desktop")
    (lambda (port)
      (format port "[Desktop Entry]~%Type=Application~%Name=AnyLogic PLE~%Comment=Simulation modeling (Guix runtime)~%Exec=~a %F~%Icon=~a/icon.xpm~%Terminal=false~%Categories=Education;Science;~%StartupWMClass=AnyLogic~%"
              launcher destination))))
(format #t "Installed AnyLogic ~a; start with ~~/.local/bin/anylogic~%" version)
