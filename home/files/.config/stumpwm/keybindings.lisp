(load ".config/stumpwm/dashboard.lisp")
(load ".config/stumpwm/internet.lisp")
(load ".config/stumpwm/screenshot.lisp")
(load ".config/stumpwm/misc.lisp")

;; Set StumpWMs prefix
(set-prefix-key (kbd "Print"))

(define-key *root-map* (kbd "Return") "exec kitty")
(define-key *root-map* (kbd "b") "exec nyxt")
(define-key *root-map* (kbd "e") "exec lem")

(define-key *root-map* (kbd "r") "exec")


;; Frame Management
(define-key *root-map* (kbd "F") "float-this")
(define-key *root-map* (kbd "n") "fnext")
(define-key *root-map* (kbd "v") "vsplit")
(define-key *root-map* (kbd "h") "hsplit")
(define-key *root-map* (kbd "c") "remove-split")

;; Window Management
(define-key *root-map* (kbd "l") "windowlist")
(define-key *root-map* (kbd "k") "kill")
(define-key *root-map* (kbd "f") "next")
(define-key *root-map* (kbd "p") "pull")
(define-key *root-map* (kbd "m") "move-window")
(define-key *root-map* (kbd "d") "delete-window")

;; Group Management
(define-key *root-map* (kbd "G") "gnew")
(define-key *root-map* (kbd "g") "gnext")

;; Start/Shutdown/...
(define-key *root-map* (kbd "R") "loadrc")

(defcommand shutdown () ()(
			   run-shell-command "shutdown"))

(define-key *root-map* (kbd "Q") "shutdown")


(define-key *root-map* (kbd "t") "dashboard")
(define-key *root-map* (kbd "T") "add-todo")


(defvar *screenshot-map* nil
  "The keymap that groups screenshot related key bindings sit on")

(fill-keymap *screenshot-map*
             (kbd ".") "screenshot"
             (kbd ",") "get-latex")

(defcommand show-screenshot-options () ()
  "Show screenshot options and enter screenshot keymap"
  (message "Screenshot Options:~%~
           . - Take screenshot~%~
           , - Get latex")
  (push-top-map *screenshot-map*))

(define-key *root-map* (kbd "S") '*screenshot-map*)

(defvar *misc-map* nil
  "The keymap that groups unrelated commands")

(fill-keymap *misc-map*
             (kbd "i") "internet-10-min"
             (kbd "t") "insert-timestamp")

(define-key *root-map* (kbd "P") '*misc-map*)


