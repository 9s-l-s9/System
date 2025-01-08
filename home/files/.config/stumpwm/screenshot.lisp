(defcommand screenshot () ()(
			     run-shell-command "flameshot gui"))

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
