(defun modeline/init-bar ()
  ;; Colors
  ;;(load "~/.cache/wal/colors.lisp")
  ;;(setf *mode-line-background-color* background)
  ;;(setf *mode-line-border-color* background)
  ;;(setf *mode-line-foreground-color* foreground)

  ;; Mode line's contents
  (setf *group-format* "%t")
  (setf *screen-mode-line-format*
        (list 
              "%g"
              "^>"
              "%d"
              ))

  ;; Refresh constantly
  (setf *mode-line-timeout* 10)

  ;; Start mode line
  (mode-line))


(defun modeline/init ()
  (modeline/init-bar))