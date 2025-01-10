(load ".config/stumpwm/colors.lisp")

(defun modeline/init-bar ()
  (setf *mode-line-background-color* base00)
  (setf *mode-line-border-color* base05)
  (setf *mode-line-foreground-color* base0B)
  (setf *mode-line-pad-x* 5)
  (setf *mode-line-pad-y* 5)
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