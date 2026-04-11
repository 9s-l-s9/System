#!/usr/bin/env -S guile -s
!#

(add-to-load-path "home")

(use-modules (srfi srfi-64)
             (srfi srfi-13)
             (services helix-home-services))

(define module-under-test
  (resolve-module '(services helix-home-services)))

(define serialize-config
  (module-ref module-under-test 'serialize-config))

(define serialize-languages-file
  (module-ref module-under-test 'serialize-languages-file))

(test-begin "helix-home-services")

(test-equal "serialize top-level and nested config"
  (string-append
   "theme = \"ayu_dark\"\n\n"
   "[editor.auto-pairs]\n"
   "'(' = \")\"\n"
   "'<' = \">\"\n")
  (serialize-config
   (list
    (helix-config #f
                  '(theme "ayu_dark"))
    (helix-config "editor.auto-pairs"
                  '("(" ")")
                  '("<" ">")))))

(test-assert "escape quotes backslashes and newlines"
  (let ((output
         (serialize-config
          (list
           (helix-config #f
                         '(banner "quote: \" slash: \\ line:\nend"))))))
    (and (string-contains output "\\\"")
         (string-contains output "\\\\")
         (string-contains output "\\n"))))

(test-assert "serialize language server and language tables"
  (let ((output
         (serialize-languages-file
          (list
           (helix-language-server
            (name "guile-lsp-server")
            (command "guile-lsp-server")
            (args '("--stdio"))))
          (list
           (helix-language
            (name "scheme")
            (config
             '((base . ((language-servers . ("guile-lsp-server"))
                        (formatter . ((command . "parinfer-rust")))))
               (auto-pairs . (("(" . ")")))))))
          '())))
    (and (string-contains output "[language-server]")
         (string-contains output "guile-lsp-server = { command = \"guile-lsp-server\", args = [\"--stdio\"] }")
         (string-contains output "formatter = { command = \"parinfer-rust\" }")
         (string-contains output "'(' = \")\""))))

(exit (if (zero? (test-runner-fail-count (test-runner-current))) 0 1))
