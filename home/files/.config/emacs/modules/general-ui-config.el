;;; general-ui-config.el --- Contains just some general UI improvements of emacs.
;;; Commentary:
;; Author: Samuel Schmidt <samuel@schmidt-contact.com>
;;;; Code:

(provide 'general-ui-config)


;; Margin
;; (setq-default left-margin-width 1 right-margin-width 1) ; Define new widths.
;; (set-window-buffer nil (current-buffer)) ; Use them now.
;; (fringe-mode 50)

;; border width for every new frame
;; (defun set-frame-border-width (frame)
;;   (set-frame-parameter frame 'internal-border-width 50))

;; Set for the initial frame
;; (set-frame-border-width (selected-frame))

;; Set for any new frames
;; (add-hook 'after-make-frame-functions 'set-frame-border-width)

;; No fringe but nice glyphs for truncated and wrapped lines
(fringe-mode '(0 . 0))
(global-visual-line-mode)


;; General
(setq widget-image-enable nil)

;; Indentation lines
(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)
(setq highlight-indent-guides-method 'character)
(setq highlight-indent-guides-auto-character-face-perc '70)


(global-hl-line-mode +1)

;; Transparency

;; (defun set-frame-transparency (&optional frame)
;;   "Set the transparency of the given frame, or the current frame if none is given."
;;   (let ((alpha-value '(90 . 100)))
;;     (when frame
;;       (select-frame frame))
;;     (set-frame-parameter frame 'alpha alpha-value)))

;; ;; Set transparency of the current frame.
;; (set-frame-transparency)

;; ;; Ensure all newly created frames have the same transparency.
;; (add-hook 'after-make-frame-functions 'set-frame-transparency)

;; Theme 
(setq custom-safe-themes t)
;; (require 'doom-themes)
(require 'doom-rouge)
;; (require 'nano-theme)
;;(load-theme 'nano-light)
;; (load-theme 'nano-light)
(load-theme 'ef-dark t)
(setq custom-safe-themes t)


;; Emoji font
(set-fontset-font t 'symbol "all-the-icons" nil 'prepend)

;; add visual pulse when changing focus, like beacon but built-in
;; from from https://karthinks.com/software/batteries-included-with-emacs/
(defun pulse-line (&rest _)
  "Pulse the current line."
  (pulse-momentary-highlight-one-line (point)))

(dolist (command '(scroll-up-command scroll-down-command
                                     recenter-top-bottom other-window))
  (advice-add command :after #'pulse-line))

;; Disable some UI elements
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;; Font and frame size
(set-face-font 'default "Courier Prime 16")

;; Line spacing, can be 0 for code and 1 or 2 for text
(setq-default line-spacing 2)
;; Underline line at descent position, not baseline position
(setq x-underline-at-descent-line t)

;; No ugly button for checkboxes
(setq widget-image-enable nil)

;; Line cursor and no blink
(set-default 'cursor-type  '(bar . 1))
(blink-cursor-mode 0)

;; No sound
(setq visible-bell t)
(setq ring-bell-function 'ignore)

;; Paren mode is part of the theme
(show-paren-mode t)

;; Line Numbers

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
;; (setq display-line-numbers 'relative)


;; Modeline
;;(require 'nano-modeline)
;;(nano-modeline-prog-mode t)
 ;; (custom-set-faces '(modeline ((t :box (:line-width 4)))))
;;(custom-set-faces
  ;; '(mode-line ((t (:box (:line-width 4 :color "white") :override t)))))

;; (setq-default header-line-format mode-line-format)

;; (require 'multiline)
(require 'min-modeline)

;; (setq-default mode-line-format'("--------"))

;; (setq window-divider-default-right-width 3)
;; (setq window-divider-default-places 'right-only)
;; (window-divider-mode)

;; (setq-default header-line-format mode-line-format)
;; (setq-default mode-line-format nil)

;; (defun generate-bottom-line ()
;;   "Generate a line of dashes that matches the window width."
;;   (let ((line-width (window-width)))
;;     (make-string (max 0 (- line-width 1)) ?-)))

;; (define-minor-mode global-mode-line-to-header-mode
;;   "A mode to move the mode line to the header globally and replace the mode line with a dynamic line."
;;   :global t
;;   (if global-mode-line-to-header-mode
;;       (progn
;;         ;; Move mode line to header
;;         (setq-default header-line-format mode-line-format)
;;         ;; Set mode line to a dynamic line of dashes
;;         (setq-default mode-line-format '(:eval (generate-bottom-line))))
;;     ;; Revert changes
;;     (setq-default header-line-format nil)
;;     (setq-default mode-line-format nil)))

;; ;; Activate the mode
;; (global-mode-line-to-header-mode 1)



;; Function to format the buffer name
;; (defun my-modeline--buffer-name ()
;;   "Return `buffer-name' with spaces around it."
;;   (format " %s" (buffer-name)))
;; ;; Function to format the major mode name
;; (defun my-modeline--major-mode-name ()
;;   "Return capitalized `major-mode' as a string."
;;   (capitalize (symbol-name major-mode)))

;; ;; Variable to show the major mode
;; (defvar-local my-modeline-major-mode
;;     '(:eval
;;       (list
;;        (propertize "λ" 'face 'shadow)
;;        " "
;;        (propertize (my-modeline--major-mode-name) 'face 'bold)))
;;   "Mode line construct to display the major mode.")
;; (put 'my-modeline-major-mode 'risky-local-variable t)

;; (defun my-modeline--vc-branch ()
;;   "Return the current VC branch."
;;   (interactive)
;;   (if vc-mode
;;       (progn
;;         (message "VC Mode is active: %s" vc-mode)
;;         vc-mode)
;;     (message "VC Mode is not active")))


;; ;; Function to show modified status
;; (defun my-modeline--modified-status ()
;;   "Return '*' if the buffer is modified."
;;   (if (buffer-modified-p) "*" " "))


;; ;; Function to show the Git branch
;; (defun my-modeline--vc-branch ()
;;   "Return the current VC branch."
;;   (when vc-mode
;;     vc-mode))  ; Directly return the vc-mode string

;; ;; Variable to show the Git branch
;; (defvar-local my-modeline-vc-branch
;;   '(:eval (my-modeline--vc-branch))
;;   "Mode line construct to display the VC branch.")


;; ;; Assembling the mode line
;; (setq-default mode-line-format
;;               '("%e"
;; 		(:eval (my-modeline--buffer-name))
;;                 (:eval (my-modeline--modified-status))  ; Modified status
;;                 " "
;;                 ;; Right-Onlyjn align (using the "mode-line-end-spaces" variable)
;;                 (:eval (propertize
;;                         " " 'display
;;                         `((space :align-to (- right ,(string-width (format-mode-line '("%l" "    " my-modeline-major-mode "git:master"))))))))
;; 		(:eval my-modeline-vc-branch)
;; 		" "
;; 		my-modeline-major-mode  ; Major mode
;; 		" %l"  ; Line number
;; 		))  ; Git branch
