(define-module (services stumpwm)
  #:use-module (gnu)
  #:use-module (stumpwm-home-service)
  #:use-module (gnu packages wm)
  #:export (stumpwm-service))

(define (stumpwm-service)
  (service home-stumpwm-service-type
         (home-stumpwm-configuration
          (package stumpwm)
          (stumpwm-modules (list sbcl-stumpwm-swm-gaps))
          (prefix-key "Print")
          (config
           (list
            #~"(asdf:load-system \"stumpwm\")"
            #~";; avoid repeating stumpwm:define-key or stumpwm:kbd instead of simply define-key and kbd."
            #~"(in-package :stumpwm)"
            #~"(defvar guix-home-path \"~/.guix-home/profile/share/\""
            #~"  \"Define Guix Home profile PATH.\")"
            #~"(setf *data-dir* \"~/.local/share/stumpwm\")"
            #~";; Modules"
            #~"(set-module-dir \"/run/current-system/profile/share/common-lisp/sbcl/\")"
            #~"(load-module \"swm-gaps\")"
            #~";; Groups"
            #~"(grename \" I \")"
            #~"(add-group (current-screen) \" II \")"
            #~"(add-group (current-screen) \" III \")"

            #~"(defcommand dashboard () ()"
            #~"(run-shell-command \"~/Projects/System/scripts/dashboard.scm\" t))"
            #~"(defcommand add-todo (todo-text) ((:string \"Enter TODO: \"))"
            #~"(run-shell-command (concatenate 'string \"~/Projects/System/scripts/add-todo.scm \" todo-text \" ~/Projects/WorkingMemory/wm.org\"))"
            #~"(format t \"Added TODO: ~A~%\" todo-text))"
            #~";; Init"
            #~"(when *initializing*"
            #~"      (run-shell-command \"picom -b\")"
            #~"      (run-shell-command \"feh --bg-fill $(find ~/Projects/images/ -type f | shuf -n 1)\")"
            #~"      (mode-line)"
            #~"      (dolist (h (screen-heads (current-screen)))"   
            #~"        (enable-mode-line (current-screen) h t))"
            #~"      (swm-gaps:toggle-gaps))"))
          (colors (list "#000000"
                        "#121212"
                        "#222222"
                        "#333333"
                        "#999999"
                        "#c1c1c1"
                        "#999999"
                        "#c1c1c1"))

          (setf-entries
           (list
            ;; Mode line
            (stumpwm-setf-entry
             (variable "*mode-line-pad-x*")
             (value 5))
            (stumpwm-setf-entry
             (variable "*mode-line-pad-y*")
             (value 5))
            (stumpwm-setf-entry
             (variable "*group-format*")
             (value "%t"))
            (stumpwm-setf-entry
             (variable "*screen-mode-line-format*")
             (value (list "%g" "^>" "%d")))            
            (stumpwm-setf-entry
             (variable "*mode-line-timeout*")
             (value 10))
            
            ;; Gaps configuration
            (stumpwm-setf-entry
             (variable "swm-gaps:*head-gaps-size*")
             (value 0))
            (stumpwm-setf-entry
             (variable "swm-gaps:*inner-gaps-size*")
             (value 10))
            (stumpwm-setf-entry
             (variable "swm-gaps:*outer-gaps-size*")
             (value 10))
            
            ;; Window configuration
            (stumpwm-setf-entry
             (variable "*ignore-wm-inc-hints*")
             (value #t))
            (stumpwm-setf-entry
             (variable "*message-window-gravity*")
             (value ':center))
            (stumpwm-setf-entry
             (variable "*input-window-gravity*")
             (value ':center))
            (stumpwm-setf-entry
             (variable "*input-completion-show-empty*")
             (value #t))))

          (keymaps
           (list
            ;; Main root-map bindings
            (stumpwm-keymap
             (name "root")
             (map-variable "stumpwm:*root-map*")
             (bindings
              (list
               ;; Applications
               (stumpwm-keybinding (key "Return") (command "exec kitty"))
               (stumpwm-keybinding (key "b") (command "exec nyxt"))
               (stumpwm-keybinding (key "e") (command "exec lem -i sdl2"))
               (stumpwm-keybinding (key "r") (command "exec"))
               
               ;; Frame Management
               (stumpwm-keybinding (key "F") (command "float-this"))
               (stumpwm-keybinding (key "n") (command "fnext"))
               (stumpwm-keybinding (key "v") (command "vsplit"))
               (stumpwm-keybinding (key "h") (command "hsplit"))
               (stumpwm-keybinding (key "c") (command "remove-split"))
               
               ;; Window Management
               (stumpwm-keybinding (key "l") (command "windowlist"))
               (stumpwm-keybinding (key "k") (command "kill"))
               (stumpwm-keybinding (key "f") (command "next"))
               (stumpwm-keybinding (key "p") (command "pull"))
               (stumpwm-keybinding (key "m") (command "move-window"))
               (stumpwm-keybinding (key "d") (command "delete-window"))
               
               ;; Group Management
               (stumpwm-keybinding (key "G") (command "gnew"))
               (stumpwm-keybinding (key "g") (command "gnext"))
               
               ;; Start/Shutdown
               (stumpwm-keybinding (key "R") (command "loadrc"))
               (stumpwm-keybinding (key "Q") (command "shutdown"))
               
               ;; Custom commands
               (stumpwm-keybinding (key "t") (command "dashboard"))
               (stumpwm-keybinding (key "T") (command "add-todo")))))
            
            ;; Screenshot map
            (stumpwm-keymap
             (name "screenshot")
             (prefix-key "S")
             (bindings
              (list
               (stumpwm-keybinding (key ".") (command "exec spectacle"))
               (stumpwm-keybinding (key ",") (command "get-latex")))))
            
            ;; Misc map
            (stumpwm-keymap
             (name "misc")
             (map-variable "*misc-map*")
             (prefix-key "P")
             (bindings
              (list
               (stumpwm-keybinding (key "s") (command "browser-search"))
               ;;(stumpwm-keybinding (key "i") (command "internet-10-min"))
               ;;(stumpwm-keybinding (key "t") (run-shell-command "date "+%Y-%m-%d" | xsel --clipboard --input"))
               )))))
          )))
