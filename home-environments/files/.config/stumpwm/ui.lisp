; Theme

;;; Base16 black metal bathory

(defvar base00 "#000000")
(defvar base01 "#121212")
(defvar base02 "#222222")
(defvar base03 "#333333")
(defvar base04 "#999999")
(defvar base05 "#c1c1c1")
(defvar base06 "#999999")
(defvar base07 "#c1c1c1")
(defvar base08 "#5f8787")
(defvar base09 "#aaaaaa")
(defvar base0A "#e78a53")
(defvar base0B "#fbcb97")
(defvar base0C "#aaaaaa")
(defvar base0D "#888888")
(defvar base0E "#999999")
(defvar base0F "#444444")

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
