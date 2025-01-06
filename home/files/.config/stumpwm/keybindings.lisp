;; Set StumpWMs prefix
(set-prefix-key (kbd "Print"))

(define-key *root-map* (kbd "Return") "exec kitty")
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


(defcommand show-downloads () ()
  "Display the files in the Downloads directory."
  (let ((output (directory "/home/samuel/Downloads/*.*")))
    (if (null output)
        (echo "Download directory is clean!")
	(echo output)
	)))


(define-key *root-map* (kbd "E") "show-downloads")
(define-key *root-map* (kbd "C") "show-uncommitted-changes")


;; Read TODOs command (unchanged from before)
(defcommand show-todos () ()
  "Show open TODOs from org file"
  (let* ((todo-file "/home/samuel/Projects/WorkingMemory/wm-t450s.org")
         (todos (with-open-file (stream todo-file)
                  (loop for line = (read-line stream nil nil)
                        while line
                        ;; First trim leading/trailing whitespace
                        for cleaned-line = (string-trim " " line)
                        ;; Check if line starts with any number of asterisks followed by TODO
                        when (and (> (length cleaned-line) 6)
                                (char= (char cleaned-line 0) #\*)
                                ;; Find position after asterisks
                                (let* ((content-start (position-if-not 
                                                     (lambda (c) (char= c #\*)) 
                                                     cleaned-line))
                                      (content (string-trim " " 
                                                          (subseq cleaned-line content-start))))
                                  (and content-start
                                       (> (length content) 4)
                                       (string= "TODO" (subseq content 0 4)))))
                        ;; Collect the actual todo text, removing asterisks and TODO
                        collect (let* ((content-start (position-if-not 
                                                     (lambda (c) (char= c #\*)) 
                                                     cleaned-line))
                                     (content (string-trim " " 
                                                         (subseq cleaned-line content-start))))
                                (string-trim " " (subseq content 4))))))
         (todo-string (if todos
                         (format nil "~{~A~^~%~}" todos)
                         "No open TODOs")))
    (message "Open TODOs:~%~A" todo-string)))

;; New command to add a TODO
(defcommand add-todo (todo-text) ((:string "Enter TODO: "))
  "Add a new TODO to the org file"
  (let ((todo-file "/home/samuel/Projects/WorkingMemory/wm-t450s.org"))
    (with-open-file (stream todo-file
                           :direction :output
                           :if-exists :append
                           :if-does-not-exist :create)
      ;; Add a newline first to ensure separation from previous content
      (format stream "~%* TODO ~A" todo-text))
    (message "Added TODO: ~A" todo-text)))

;; Key bindings
(define-key *root-map* (kbd "t") "show-todos")
(define-key *root-map* (kbd "T") "add-todo")


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



