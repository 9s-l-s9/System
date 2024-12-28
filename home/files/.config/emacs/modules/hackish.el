(provide 'hackish)

(defun reload-init-file ()
  (interactive)
  (server-force-delete)
  (load-file user-init-file))
