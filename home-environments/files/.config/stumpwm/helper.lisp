(defun get-random-file (directory)
  "Returns a random file from the specified directory"
  (let* ((files (directory (concatenate 'string directory "/*.*")))
         (file-count (length files)))
    (if (> file-count 0)
        (nth (random file-count) files)
        nil)))
