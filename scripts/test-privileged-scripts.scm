#!/usr/bin/env -S guix repl -q --
!#
;;; Build and inspect privileged programs; never run their sysfs operations.
(add-to-load-path (string-append (dirname (current-filename)) "/../systems"))
(use-modules (privileged-scripts) (guix gexp) (guix store)
             (guix derivations) (guix monads) (ice-9 textual-ports) (srfi srfi-64))

(define outputs
  (with-store store
    (let* ((items (list (@@ (privileged-scripts) low-power-program)
                        (@@ (privileged-scripts) keyboard-program)
                        (privileged-sudoers "samuel" #:keyboard? #t)
                        (privileged-sudoers "samuel")))
           (drvs (map (lambda (item)
                        (run-with-store store (lower-object item)))
                      items)))
      (build-derivations store (filter derivation? drvs))
      (map (lambda (item)
             (if (derivation? item) (derivation->output-path item) item))
           drvs))))

(test-begin "privileged-programs")
(for-each
 (lambda (file)
   (test-equal "store program owned by root" 0 (stat:uid (stat file)))
   (test-assert "store program not writable"
     (zero? (logand #o222 (stat:perms (stat file)))))
   (test-assert "store program loads immutable source"
     (string-contains (call-with-input-file file get-string-all) "primitive-load \"/gnu/store/"))
   (test-equal "unexpected arguments rejected without touching sysfs" 2
     (status:exit-val (system* file "invalid-argument"))))
 (list-head outputs 2))
(test-equal "keyboard rejects extra arguments" 2
  (status:exit-val (system* (cadr outputs) "on" "unexpected")))
(for-each
 (lambda (file)
   (test-equal "sudoers parses" 0
     (status:exit-val (system* "/run/current-system/profile/sbin/visudo" "-c" "-f" file)))
   (test-assert "no checkout path in sudoers"
     (not (string-contains (call-with-input-file file get-string-all) "/Projects/"))))
 (list-tail outputs 2))
(define failures (test-runner-fail-count (test-runner-current)))
(test-end "privileged-programs")
(exit (if (zero? failures) 0 1))
