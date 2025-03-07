; Modeline


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
  (modeline/init-bar)
  (dolist (h (screen-heads (current-screen)))   
    (enable-mode-line (current-screen) h t))
  )

; Gaps

(load-module "swm-gaps")

(setf swm-gaps:*head-gaps-size*  0
      swm-gaps:*inner-gaps-size* 10
      swm-gaps:*outer-gaps-size* 10)


; Windows

(setf *ignore-wm-inc-hints* t)
(setf *message-window-gravity* :center)
(setf *message-input-window-gravity* :center)
(setf *input-window-gravity* :center)
(setf *input-completion-show-empty* t)
