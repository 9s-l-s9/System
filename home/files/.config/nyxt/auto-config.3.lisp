(defmethod customize-instance ((browser browser) &key)
  (setf (slot-value browser 'default-new-buffer-url)
          "https://gitlab.com/s-l-s")
  (setf (slot-value browser 'restore-session-on-startup-p) nil))
