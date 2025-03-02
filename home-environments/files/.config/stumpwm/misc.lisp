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


(defcommand insert-timestamp () ()
  "Insert current date"
  (multiple-value-bind (sec min hour day month year) (get-decoded-time)
    (window-send-string 
     (format nil "~4,'0d-~2,'0d-~2,'0d" year month day))))
