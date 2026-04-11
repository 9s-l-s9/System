(define-module (services helix-home-services)
  #:use-module (gnu home services)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (home-helix-service-type
            home-helix-configuration
            helix-config
            helix-language
            helix-grammar
            helix-language-server))

(define (string-or-gexp? value)
  (or (string? value) (gexp? value)))

(define (gexp-text-config? value)
  (and (list? value) (every string-or-gexp? value)))

(define (serialize-gexp-text-config field-name value)
  #~(string-append #$@(interpose value "\n" 'suffix)))

(define-record-type* <helix-section>
  helix-section make-helix-section
  helix-section?
  (name helix-section-name)
  (values helix-section-values))

(define (helix-config name . key-value-pairs)
  (helix-section
   (name name)
   (values
    (map (lambda (entry)
           (cond
            ((not (pair? entry))
             (cons entry #t))
            ((pair? (cdr entry))
             (cons (car entry) (cadr entry)))
            (else
             (cons (car entry) #t))))
         key-value-pairs))))

(define-record-type* <helix-language>
  helix-language make-helix-language
  helix-language?
  (name helix-language-name)
  (config helix-language-config
          (default '())))

(define-record-type* <helix-language-server>
  helix-language-server make-helix-language-server
  helix-language-server?
  (name helix-language-server-name)
  (command helix-language-server-command)
  (args helix-language-server-args
        (default '())))

(define-record-type* <helix-grammar>
  helix-grammar make-helix-grammar
  helix-grammar?
  (name helix-grammar-name)
  (source helix-grammar-source))

(define (helix-sections? value)
  (and (list? value) (every helix-section? value)))

(define (helix-languages? value)
  (and (list? value) (every helix-language? value)))

(define (helix-language-servers? value)
  (and (list? value) (every helix-language-server? value)))

(define (helix-grammars? value)
  (and (list? value) (every helix-grammar? value)))

(define (escape-basic-string str)
  (call-with-output-string
    (lambda (port)
      (string-for-each
       (lambda (chr)
         (cond
          ((char=? chr #\\) (display "\\\\" port))
          ((char=? chr #\") (display "\\\"" port))
          ((char=? chr #\newline) (display "\\n" port))
          (else (write-char chr port))))
       str))))

(define (toml-string str)
  (string-append "\"" (escape-basic-string str) "\""))

(define (toml-literal-key key)
  (string-append "'" key "'"))

(define (bare-key-char? chr)
  (or (char-alphabetic? chr)
      (char-numeric? chr)
      (char=? chr #\_)
      (char=? chr #\-)
      (char=? chr #\.)))

(define (toml-key value)
  (let ((key (if (symbol? value)
                 (symbol->string value)
                 value)))
    (if (and (string? key)
             (not (string-null? key))
             (every bare-key-char? (string->list key)))
        key
        (toml-literal-key key))))

(define (toml-value value)
  (cond
   ((string? value) (toml-string value))
   ((boolean? value) (if value "true" "false"))
   ((number? value) (number->string value))
   ((symbol? value) (symbol->string value))
   ((and (list? value) (every pair? value))
    (string-append
     "{ "
     (string-join
      (map (lambda (entry)
             (string-append
              (toml-key (car entry))
              " = "
              (toml-value (cdr entry))))
           value)
      ", ")
     " }"))
   ((list? value)
    (string-append
     "["
     (string-join (map toml-value value) ", ")
     "]"))
   (else
    (format #f "~a" value))))

(define (serialize-section section)
  (match-record section <helix-section>
    (name values)
    (let ((body (string-join
                 (map (lambda (entry)
                        (string-append
                         (toml-key (car entry))
                         " = "
                         (toml-value (cdr entry))))
                      values)
                 "\n")))
      (string-append
       (if (and name (not (string-null? name)))
           (string-append "[" name "]\n")
           "")
       body
       "\n"))))

(define (serialize-config sections)
  (string-join (map serialize-section sections) "\n"))

(define (serialize-language-server server)
  (match-record server <helix-language-server>
    (name command args)
    (string-append
     (toml-key name)
     " = { command = "
     (toml-value command)
     (if (null? args)
         ""
         (string-append ", args = " (toml-value args)))
     " }\n")))

(define (serialize-language-servers servers)
  (if (null? servers)
      ""
      (string-append
       "[language-server]\n"
       (string-join (map serialize-language-server servers) "")
       "\n")))

(define (serialize-language lang)
  (match-record lang <helix-language>
    (name config)
    (let* ((base-entry (assoc 'base config))
           (base-config (if base-entry (cdr base-entry) '()))
           (sections (filter (lambda (entry) (not (eq? (car entry) 'base))) config))
           (base-lines
            (map (lambda (entry)
                   (string-append
                    (toml-key (car entry))
                    " = "
                    (toml-value (cdr entry))))
                 base-config))
           (section-lines
            (map (lambda (entry)
                   (string-append
                    (toml-key (car entry))
                    " = "
                    (toml-value (cdr entry))))
                 sections)))
      (string-append
       "[[language]]\n"
       "name = "
       (toml-value name)
       "\n"
       (string-join (append base-lines section-lines) "\n")
       "\n\n"))))

(define (serialize-grammar grammar)
  (match-record grammar <helix-grammar>
    (name source)
    (string-append
     "[[grammar]]\n"
     "name = "
     (toml-value name)
     "\nsource = "
     (toml-value source)
     "\n\n")))

(define (serialize-languages-file language-servers languages grammars)
  (string-append
   (serialize-language-servers language-servers)
   (string-join (map serialize-language languages) "")
   (string-join (map serialize-grammar grammars) "")))

(define-configuration/no-serialization home-helix-configuration
  (package
    (package (specification->package "helix"))
    "The Helix package to use.")
  (config
   (helix-sections '())
   "List of Helix config sections created with @code{helix-config}.")
  (language-servers
   (helix-language-servers '())
   "List of language servers created with @code{helix-language-server}.")
  (languages
   (helix-languages '())
   "List of language definitions created with @code{helix-language}.")
  (grammars
   (helix-grammars '())
   "List of grammar definitions created with @code{helix-grammar}.")
  (extra-config
   (gexp-text-config '())
   "List of raw strings or gexps appended to @file{config.toml}."))

(define (helix-files-service cfg)
  (match-record cfg <home-helix-configuration>
    (config language-servers languages grammars extra-config)
    (let ((config-file
           (mixed-text-file
            "helix-config.toml"
            (serialize-config config)
            (if (null? extra-config)
                ""
                (serialize-gexp-text-config #f extra-config))))
          (languages-file
           (mixed-text-file
            "helix-languages.toml"
            (serialize-languages-file language-servers languages grammars))))
      `(("helix/config.toml" ,config-file)
        ("helix/languages.toml" ,languages-file)))))

(define (helix-profile-service cfg)
  (match-record cfg <home-helix-configuration>
    (package)
    (list package)))

(define home-helix-service-type
  (service-type
   (name 'home-helix)
   (extensions
    (list (service-extension
           home-profile-service-type
           helix-profile-service)
          (service-extension
           home-xdg-configuration-files-service-type
           helix-files-service)))
   (description "Install and configure the Helix editor.")))
