(define-module (packages emacs-build)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages emacs)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:export (emacs-next-pgtk-for-build))

;; The Emacs used to *build* Emacs Lisp packages (see `for-emacs-next' in
;; packages/base-packages.scm).  It is the runtime `emacs-next-pgtk' itself
;; -- same binary, so the .eln it produces carry the runtime's ABI hash --
;; behind a thin bin/emacs wrapper that keeps Emacs 31's autoload generation
;; working under Guix.
;;
;; `loaddefs-generate' in Emacs 31 loads a file whose autoloaded form uses
;; an unknown macro (`cl-defun', `defmacro*' ...) with `load-suffixes' bound
;; to (".el") only.  That load pulls in cl-lib from its compressed source
;; cl-lib.el.gz, whose decompression needs jka-compr, which in the `--quick
;; --batch' build session is itself only found as jka-compr.el.gz (and
;; loading that source in turn needs gv.el.gz ...): a recursive load, and
;; the package's make-autoloads phase fails.  Loading jka-compr from its
;; .elc before anything else breaks the cycle.  The wrapper inserts
;; `-l jka-compr' after Emacs' initial options (`--quick', `--batch' and
;; friends must stay in front) and before the action options.  Emacs 30's
;; loaddefs-gen never loads files, which is why upstream Guix does not hit
;; this.  Only this build-time Emacs is wrapped; the runtime is untouched.
(define emacs-next-pgtk-for-build
  (package
    (inherit emacs-next-pgtk)
    (name "emacs-next-pgtk-for-build")
    (outputs (list "out"))
    (source #f)
    (build-system trivial-build-system)
    (native-inputs '())
    (propagated-inputs '())
    (inputs (list bash-minimal emacs-next-pgtk))
    (arguments
     (list
      #:modules '((guix build utils) (guix build union))
      #:builder
      #~(begin
          (use-modules (guix build utils) (guix build union))
          (let* ((emacs #$(this-package-input "emacs-next-pgtk"))
                 (sh (string-append #$(this-package-input "bash-minimal") "/bin/sh"))
                 (wrapper (string-append #$output "/bin/emacs")))
            (union-build #$output (list emacs) #:create-all-directories? #t)
            (delete-file wrapper)
            (call-with-output-file wrapper
              (lambda (port)
                (format port "#!~a
# Preload jka-compr (from its .elc) so Emacs 31's loaddefs-generate can
# decompress .el.gz sources while `load-suffixes' is restricted to .el.
# Initial options must precede it; everything else follows.
# With --script Emacs moves the script to the front and hands every other
# argument to it, so an inserted -l would reach the script as data.  Such
# invocations (test runners) never generate autoloads: leave them alone.
for arg in \"$@\"; do
  case \"$arg\" in --script|-x|-scriptload) exec ~a/bin/emacs \"$@\" ;; esac
done
initial=()
while [ $# -gt 0 ]; do
  case \"$1\" in
    -Q|--quick|-q|--no-init-file|--batch|-batch|--no-site-file|-nsl|--no-site-lisp|--no-splash|-nw)
      initial+=(\"$1\"); shift ;;
    -t|--terminal|--display|-d|-u|--user|--chdir|--init-directory)
      initial+=(\"$1\" \"$2\"); shift 2 ;;
    --init-directory=*|--display=*|--terminal=*|--user=*|--chdir=*)
      initial+=(\"$1\"); shift ;;
    *) break ;;
  esac
done
exec ~a/bin/emacs \"${initial[@]}\" -l jka-compr \"$@\"
" sh emacs emacs)))
            (chmod wrapper #o555)))))
    (synopsis "Emacs used for building Emacs Lisp packages in this configuration")))
