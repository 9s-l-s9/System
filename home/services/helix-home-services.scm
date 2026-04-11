(define-module (services helix-home-services)
  #:use-module (gnu home services)
  #:use-module (gnu packages editors)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (guix packages)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 match)

  #:export (home-helix-service-type
            home-helix-configuration
            helix-config
            helix-language
            helix-grammar
            helix-language-server))

;;; Commentary:
;;;
;;; This module contains services for the Helix editor.
;;;
;;; Code:

;;;
;;; Utils
;;;

(define (package+out? entry)
  (or (package? entry) (package? (car entry))))

(define packages? (list-of package+out?))

(define path? string?)
(define (serialize-path field-name val) val)

(define (string-or-gexp? sg) (or (string? sg) (gexp? sg)))
(define (serialize-string-or-gexp field-name val) "")

;; For text configurations
(define (gexp-text-config? config)
  (and (list? config) (every string-or-gexp? config)))
(define (serialize-gexp-text-config field-name val)
  #~(string-append #$@(interpose val "\n" 'suffix)))

;;;
;;; Helix configuration helpers
;;;

;; A more convenient way to specify configuration
(define-record-type* <helix-section>
  helix-section make-helix-section
  helix-section?
  (name helix-section-name)           ;; string
  (values helix-section-values))      ;; alist of key-value pairs

;; Helper function to transform configuration into internal format
(define (process-helix-config config)
  (map (lambda (section)
         (match-record section <helix-section>
           (name values)
           (map (lambda (key-value)
                  (cons (string-append name "." (symbol->string (car key-value)))
                        (cdr key-value)))
                values)))
       config))

;; Public function to create a config section
(define (helix-config name . key-value-pairs)
  (helix-section
   (name name)
   (values (map (lambda (pair)
                  (cons (car pair) (cadr pair)))
                (map (lambda (x) (if (pair? x) x (list x #t)))
                     key-value-pairs)))))

;;;
;;; Language configuration
;;;

(define-record-type* <helix-language>
  helix-language make-helix-language
  helix-language?
  (name helix-language-name)                ;; string
  (config helix-language-config             ;; alist
          (default '())))

(define-record-type* <helix-language-server>
  helix-language-server make-helix-language-server
  helix-language-server?
  (name helix-language-server-name)         ;; string
  (command helix-language-server-command)   ;; string
  (args helix-language-server-args          ;; list of strings
        (default '())))

(define-record-type* <helix-grammar>
  helix-grammar make-helix-grammar
  helix-grammar?
  (name helix-grammar-name)                ;; string
  (source helix-grammar-source))           ;; alist

;;;
;;; TOML Serialization
;;;

(define (toml-escape-string str)
  (string-append "\"" str "\""))

(define (toml-serialize-value val)
  (cond
   ((number? val) (format #f "~a" val))
   ((string? val) (toml-escape-string val))
   ((boolean? val) (if val "true" "false"))
   ((symbol? val) (format #f "~a" val))
   ((and (list? val) (every pair? val))  ; It's an alist
    (format #f "{ ~a }" 
            (string-join (map (lambda (pair)
                                (string-append 
                                 (toml-escape-string 
                                  (if (symbol? (car pair))
                                      (symbol->string (car pair))
                                      (car pair)))
                                 " = " 
                                 (toml-serialize-value (cdr pair))))
                              val)
                          ", ")))
   ((list? val) 
    (format #f "[~a]" 
            (string-join (map toml-serialize-value val) ", ")))
   (else (format #f "~a" val))))

;;;
;;; Config Serialization
;;;

(define (extract-section path)
  (let* ((parts (string-split path #\.))
         (section (car parts)))
    section))

(define (extract-key path)
  (let* ((parts (string-split path #\.))
         (key (string-join (cdr parts) ".")))
    key))

(define (group-by-section config)
  (fold (lambda (entry result)
          (let* ((path (car entry))
                 (value (cdr entry))
                 (section (extract-section path))
                 (key (extract-key path))
                 (existing (assoc section result)))
            (if existing
                (map (lambda (item)
                       (if (equal? (car item) section)
                           (cons section 
                                 (cons (cons key value) (cdr item)))
                           item))
                     result)
                (cons (cons section (list (cons key value))) result))))
        '()
        config))

(define (serialize-config config)
  (let* ((flattened-config 
          (apply append (process-helix-config config)))
         (grouped (group-by-section flattened-config))
         (serialized-sections
          (map (lambda (section-group)
                 (let ((section (car section-group))
                       (entries (cdr section-group)))
                   (string-append
                    "[" section "]\n"
                    (string-join
                     (map (lambda (entry)
                            (string-append (car entry) " = " 
                                           (toml-serialize-value (cdr entry))))
                          entries)
                     "\n")
                    "\n")))
               grouped)))
    (string-join serialized-sections "\n")))

;;;
;;; Language Server Serialization
;;;

(define (serialize-language-server server)
  (match-record server <helix-language-server>
    (name command args)
    (format #f "~a = { command = ~s~a }\n"
            name
            command
            (if (null? args)
                ""
                (format #f ", args = ~a" 
                        (toml-serialize-value args))))))

(define (serialize-language-servers servers)
  (if (null? servers)
      ""
      (string-append
       "[language-server]\n"
       (string-join (map serialize-language-server servers) "")
       "\n")))

;;;
;;; Language Serialization
;;;

(define (serialize-language lang)
  (match-record lang <helix-language>
    (name config)
    
    (let* ((base-config (assoc-ref config 'base '()))
           (sub-sections (filter (lambda (pair) 
                                   (not (eq? (car pair) 'base)))
                                 config)))
      
      (string-append
       "[[language]]\n"
       "name = " (toml-escape-string name) "\n"
       (string-join 
        (map (lambda (pair)
               (string-append (symbol->string (car pair)) " = " 
                              (toml-serialize-value (cdr pair))))
             base-config)
        "\n")
       "\n"
       (string-join
        (map (lambda (section)
               (let ((section-name (car section))
                     (section-config (cdr section)))
                 (string-append 
                  "[language." (symbol->string section-name) "]\n"
                  (string-join
                   (map (lambda (pair)
                          (string-append 
                           (if (string? (car pair))
                               (car pair)
                               (symbol->string (car pair)))
                           " = " 
                           (toml-serialize-value (cdr pair))))
                        section-config)
                   "\n"))))
             sub-sections)
        "\n\n")
       "\n"))))

;;;
;;; Grammar Serialization
;;;

(define (serialize-grammar grammar)
  (match-record grammar <helix-grammar>
    (name source)
    (string-append
     "[[grammar]]\n"
     "name = " (toml-escape-string name) "\n"
     "source = " (toml-serialize-value source) "\n\n")))

;;;
;;; Languages File Serialization
;;;

(define (serialize-languages-file language-servers languages grammars)
  (string-append
   (serialize-language-servers language-servers)
   (string-join (map serialize-language languages) "")
   (string-join (map serialize-grammar grammars) "")))

;;;
;;; Helix Configuration
;;;

(define-configuration/no-serialization home-helix-configuration
  (package
    (package helix)
    "The Helix package to use.")
  (config
   (list '())
   "List of configuration sections for Helix. Each section is created with @code{helix-config}.")
  (language-servers
   (list '())
   "List of language servers for Helix. Each server is created with @code{helix-language-server}.")
  (languages
   (list '())
   "List of language configurations for Helix. Each entry is created with @code{helix-language}.")
  (grammars
   (list '())
   "List of grammar configurations for Helix. Each entry is created with @code{helix-grammar}.")
  (extra-config
   (gexp-text-config '())
   "List of strings or gexps containing additional Helix configuration."))

(define (helix-files-service cfg)
  (match-record cfg <home-helix-configuration>
    (config language-servers languages grammars extra-config)
    
    (let ((config-file
           (mixed-text-file 
            "helix-config"
            (serialize-config config)
            (if (null? extra-config)
                ""
                (serialize-gexp-text-config #f extra-config))))
          (languages-file
           (mixed-text-file 
            "helix-languages"
            (serialize-languages-file language-servers languages grammars))))
      
      `(("helix/config.toml" ,config-file)
        ("helix/languages.toml" ,languages-file)))))

(define (helix-profile-service cfg)
  (match-record cfg <home-helix-configuration>
    (package)
    (list package)))

(define home-helix-service-type
  (service-type (name 'home-helix)
                (extensions
                 (list (service-extension
                        home-profile-service-type
                        helix-profile-service)
                       (service-extension
                        home-xdg-configuration-files-service-type
                        helix-files-service)))
                (description "\
Install and configure Helix, a post-modern text editor.")))

(define (generate-home-helix-documentation)
  (generate-documentation
   `((home-helix-configuration
      ,home-helix-configuration-fields))
   'home-helix-configuration))
