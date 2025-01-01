; Theme
(setf *colors* '("#140A1D" ;; Black
		 "#b52a5b" ;; Red
		 "#ff4971" ;; Green
		 "#8897f4" ;; Yellow
		 "#bd93f9" ;; Blue
		 "#e9729d" ;; Magenta
		 "#f18fb0" ;; Cyan
		 "#f1c4e0")) ;; White
(update-color-map (current-screen))


; Windows
(setf *ignore-wm-inc-hints* t)
(setf *message-window-gravity* :center)
(setf *message-input-window-gravity* :center)
(setf *input-window-gravity* :center)
(setf *input-completion-show-empty* t)
