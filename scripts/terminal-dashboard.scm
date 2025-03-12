#!/usr/bin/env guile
!#

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (srfi srfi-1)
	     (srfi srfi-19))  ; list operations

(define (my-string-split str delim)
  "Split string by delimiter character and return a list of strings"
  (let loop ((chars (string->list str))
             (current "")
             (result '()))
    (cond
     ((null? chars)
      (reverse (cons current result)))
     ((char=? (car chars) delim)
      (loop (cdr chars)
            ""
            (cons current result)))
     (else
      (loop (cdr chars)
            (string-append current (string (car chars)))
            result)))))

(define (get-terminal-size)
  "Get terminal width and height"
  (let* ((port (open-input-pipe "stty size"))
         (size (read-line port))
         (parts (my-string-split size #\space))
         (height (string->number (car parts)))
         (width (string->number (cadr parts))))
    (close-pipe port)
    (cons width height)))

(define (center-x str width)
  "Center text horizontally"
  (let* ((lines (my-string-split str #\newline))
         (first-line (car lines))
         (line-len (string-length first-line))
         (padding (quotient (- width line-len) 2)))
    (if (<= padding 0)
        ""
        (let ((pad-str (make-string padding #\space)))
          (string-join 
            (map (lambda (line) 
                   (string-append pad-str line)) 
                 lines) 
            "\n")))))

(define (center-y str height fill?)
  "Center text vertically"
  (let* ((lines (my-string-split str #\newline))
         (padding (+ 1 (quotient (- height (length lines)) 2)))
         (pad-str (make-string padding #\newline)))
    (if (<= padding 0)
        ""
        (string-append pad-str str (if fill? pad-str "")))))

(define (clear-screen)
  "Clear the terminal screen"
  ;; printf '\e[2J\e[H'
  (display "\033[2J\033[1;1H"))

(define (format-options options)
  "Format the menu options"
  (let loop ((opts options)
             (result "")
             (break-count 0))
    (if (null? opts)
        result
        (let* ((option (car opts))
               (name (car option))
               (icon (cadr option))
               (shortcut (caddr option))
               (command (cadddr option))
               (break-pad (if (= (modulo (+ break-count 1) 2) 0) "\n" "\t"))
               (formatted (format #f "~a ~a [:~a]~a" icon name shortcut break-pad)))
          (loop (cdr opts)
                (string-append result formatted)
                (+ break-count 1))))))

;; Define string-join for compatibility
(define (string-join lst delimiter)
  (if (null? lst)
      ""
      (let loop ((strs (cdr lst))
                 (result (car lst)))
        (if (null? strs)
            result
            (loop (cdr strs)
                  (string-append result delimiter (car strs)))))))


(define (main)
  (let* ((term-size (get-terminal-size))
         (width (car term-size))
         (height (cdr term-size))
         (ascii-art"██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗
██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝
██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗  
██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝  
╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗
 ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝")
         (username (getenv "USER"))
         (subtitle (format #f "~a" username))
         (options 
          (list 
           (list "Text Editor" " " "t" "hx")
           (list "Fetch" " " "f" "fastfetch")
           (list "Bash" " " "bs" "bash")
	   ))
         (formatted-options (format-options options))
         (screen (format #f "~a\n~a\n~a\n" 
                         (center-x ascii-art width)
                         (center-x subtitle width)
                         (center-x formatted-options width))))
    
    ;; Display initial screen
    (clear-screen)
    (display (center-y screen height #t))
    
    (let loop ()
      (display ":")
      (let ((input (read-line)))
        (cond
         ((string=? input "q")
          (clear-screen)
          (exit 0))
         ((string=? input "main")
          (clear-screen)
          (display (center-y screen height #t))
	  )
         
         (else
          (let ((matched-option (find (lambda (opt)
                                        (string=? (caddr opt) input))
                                      options)))
            (if matched-option
                (begin
                  (clear-screen)
                  (system (cadddr matched-option))
		  )
                (loop))))))
      (loop))))

;; Run the main function
(main)
