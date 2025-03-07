(defcommand dashboard () ()
	    (run-shell-command "~/Projects/System/scripts/dashboard.scm" t))

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


(defcommand add-todo (todo-text) ((:string "Enter TODO: "))
  "Add a new TODO to the org file, including the current date."
  (let* ((hostname (string-trim '(#\Newline)
                                  (run-shell-command "hostname" t)))
         (todo-file (concatenate 'string "/home/samuel/Projects/WorkingMemory/wm-" hostname ".org"))
         (date-string (multiple-value-bind (sec min hour day month year)
                           (get-decoded-time)
                         (format nil "~4,'0d-~2,'0d-~2,'0d" year month day))))
    (with-open-file (stream todo-file
                            :direction :output
                            :if-exists :append
                            :if-does-not-exist :create)
      ;; Add a newline first to ensure separation from previous content
      (format stream "~%* TODO ~A ~A" date-string todo-text))
    (format t "Added TODO: ~A~%" todo-text)))
