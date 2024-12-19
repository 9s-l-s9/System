(provide 'min-modeline)


(defun set-face (face style)
  ;; "Reset a face and make it inherit style."
  (set-face-attribute face nil
                      :foreground 'unspecified
                      :background 'unspecified
                      :family 'unspecified
                      :slant 'unspecified
                      :weight 'unspecified
                      :height 'unspecified
                      :underline 'unspecified
                      :overline 'unspecified
                      :box 'unspecified
                      :inherit (or style 'unspecified)))


;; This line below makes things a bit faster
(set-fontset-font "fontset-default"  '(#x2600 . #x26ff) "Lato 16")

 (define-key mode-line-major-mode-keymap [header-line]
   (lookup-key mode-line-major-mode-keymap [mode-line]))

(defun mode-line-render (left right)
  "Function to render the modeline LEFT to RIGHT."
  (concat left
          (propertize " " 'display `(space :align-to (- right ,(length right))))
          right))
(setq-default mode-line-format
     '((:eval
       (mode-line-render
       (format-mode-line (list
         " %b "
         (if (and buffer-file-name (buffer-modified-p))
             (propertize "(modified)" ))))
       (format-mode-line
        (propertize "%4l:%2c" ))))))


;; Comment if you want to keep the modeline at the bottom
(setq-default header-line-format mode-line-format)
(setq-default mode-line-format'(""))

              
;; Vertical window divider
(setq window-divider-default-right-width 3)
(setq window-divider-default-places 'right-only)
(window-divider-mode)



;; Modeline
(defun set-modeline-faces ()

  ;; Mode line at top
  (set-face 'header-line                                 'face-strong)
  (set-face-attribute 'header-line nil
                                :underline (face-foreground 'default))
  (set-face-attribute 'mode-line nil
                      :height 10
                      :underline (face-foreground 'default)
                      :overline nil
                      :box nil 
                      :foreground (face-background 'default)
                      :background (face-background 'default))
  (set-face 'mode-line-inactive                            'mode-line)
  
  (set-face-attribute 'cursor nil
                      :background (face-foreground 'default))
  (set-face-attribute 'window-divider nil
                      :foreground (face-background 'mode-line))
  (set-face-attribute 'window-divider-first-pixel nil
                      :foreground (face-background 'default))
  (set-face-attribute 'window-divider-last-pixel nil
                      :foreground (face-background 'default))
  )

(set-modeline-faces)
