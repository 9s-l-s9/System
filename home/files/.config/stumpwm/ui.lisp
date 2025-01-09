(load ".config/stumpwm/colors.lisp")
; Theme
(setq *colors*
      `(,base00   ;; 0 black
        ,base08   ;; 1 green
        ,base0B   ;; 2 yellow
        ,base0A   ;; 3 orange
        ,base0D   ;; 4 grey
        ,base0E   ;; 5 light grey
        ,base0C   ;; 6 light grey 2
        ,base05)) ;; 7 light grey 3

(update-color-map (current-screen))


; Windows
(setf *ignore-wm-inc-hints* t)
(setf *message-window-gravity* :center)
(setf *message-input-window-gravity* :center)
(setf *input-window-gravity* :center)
(setf *input-completion-show-empty* t)
