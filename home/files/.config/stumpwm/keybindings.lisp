;; Set StumpWMs prefix
(set-prefix-key (kbd "Print"))


(define-key *root-map* (kbd "Return") "exec konsole")
(define-key *root-map* (kbd "b") "exec nyxt")
(define-key *root-map* (kbd "e") "exec emacsclient -c")

(defcommand launcher () ()
  (run-shell-command
   "rofi -show-icons -show drun"))

(define-key *root-map* (kbd "r") "launcher")


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

;; Group Management

(define-key *root-map* (kbd "G") "gnew")
(define-key *root-map* (kbd "g") "gnext")

;; Start/Shutdown/...
(define-key *root-map* (kbd "R") "loadrc")
(define-key *root-map* (kbd "d") "delete-window")	

(defcommand shutdown () ()(
			   run-shell-command "shutdown"))

(define-key *root-map* (kbd "Q") "shutdown")


(defcommand show-uncommitted-changes () ()
  "Display projects with uncommitted changes."
  (let ((output (run-shell-command "~/.config/stumpwm/check-uncommitted.sh" t)))
    (if (string= output "")
        (echo "All projects are clean!")
        (echo output))))


(define-key *root-map* (kbd "E") "show-uncommitted-changes")

;; Screenshots
(defcommand screenshot () ()(
run-shell-command "flameshot gui"))

(define-key *root-map* (kbd ".") "screenshot")
(defcommand get-latex () ()
  "Capture a screenshot of a selected area using Flameshot's GUI, process it with pix2tex."
  (let* ((save-dir "~/Images/") 
         (filename (run-shell-command "date +'%Y%m%d%H%M%S'.png" t))
         (save-path (concatenate 'string save-dir filename)))
    ;; Capture the screenshot using Flameshot's GUI
    (run-shell-command (concatenate 'string "flameshot gui -p " save-dir))
    ;; Give a small delay to ensure flameshot has saved the screenshot before processing.
    (sleep 1)
    ;; Process the screenshot with pix2tex
    (run-shell-command (concatenate 'string "pix2tex " save-path))))

(define-key *root-map* (kbd ",") "get-latex")

;; Productivity hacks?

(defun toggle-internet ()
  "Toggle Wi-Fi on or off. Needs nmcli."
  (let ((status (uiop:run-program '("nmcli" "-t" "-f" "WIFI" "radio") :output :string)))
    (if (string= (string-trim '(#\Newline #\Return) status) "enabled")
        (run-shell-command "nmcli radio wifi off")
        (run-shell-command "nmcli radio wifi on"))))

(defun toggle-internet-after-delay (delay)
  "Turn off the internet after a specified delay."
  (run-with-timer delay nil  ;; `delay` is the time in seconds
                  (lambda ()
                    (toggle-internet))))

(defcommand internet-10-min () ()
  "Turn on the internet but only for 10 minutes to do a quick task."
  (progn
    (toggle-internet)                ;; Turn on the internet
    (toggle-internet-after-delay 600)))  ;; Schedule turning it off after 600 seconds


(define-key *root-map* (kbd "i") "internet-10-min")



