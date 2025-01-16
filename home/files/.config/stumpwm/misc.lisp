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


(defcommand insert-timestamp () ()
  "Insert current date"
  (multiple-value-bind (sec min hour day month year) (get-decoded-time)
    (window-send-string 
     (format nil "~4,'0d-~2,'0d-~2,'0d" year month day))))
