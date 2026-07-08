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
            #~"(setf *colors*"
            #~"      '(\"#282828\""
            #~"        \"#cc241d\""
            #~"        \"#98971a\""
            #~"        \"#d79921\""
            #~"        \"#458588\""
            #~"        \"#b16286\""
            #~"        \"#689d6a\""
            #~"        \"#ebdbb2\"))"
            #~"(update-color-map (current-screen))"
            #~"(setf *mode-line-background-color* \"#000000\")"
            #~"(setf *mode-line-foreground-color* \"#d79921\")"
            #~"(setf *mode-line-border-color* \"#cc241d\")"
            #~";; Groups"
            #~"(grename \" I \")"
            #~"(add-group (current-screen) \" II \")"
            #~"(add-group (current-screen) \" III \")"
            #~"(defcommand terminal-dashboard () ()"
            #~"(run-shell-command \"~/Projects/System/scripts/terminal-dashboard.scm\" t))"
            #~"(defcommand dashboard () ()"
            #~"(run-shell-command \"~/Projects/System/scripts/dashboard.scm\" t))"
            #~"(defcommand add-todo (todo-text) ((:string \"Enter TODO: \"))"
            #~"(run-shell-command (concatenate 'string \"~/Projects/System/scripts/add-todo.scm \\\"\" todo-text \"\\\" ~/Projects/WorkingMemory/wm.org\"))"
            #~"(format t \"Added TODO: ~A~%\" todo-text))"
            #~"(defcommand codex-agent () ()"
            #~"(run-shell-command \"alacritty -e ~/Projects/System/scripts/codex-guix.scm\"))"
            #~"(defcommand claude-agent () ()"
            #~"(run-shell-command \"alacritty -e ~/Projects/System/scripts/claude-guix.scm\"))"
            #~"(defcommand opencode-agent () ()"
            #~"(run-shell-command \"alacritty -e ~/Projects/System/scripts/open-code-guix.scm\"))"
            #~"(defcommand pi-agent () ()"
            #~"(run-shell-command \"alacritty -e ~/Projects/System/scripts/pi-guix.scm\"))"
            #~"(defcommand voice-dictate () ()"
            #~"(run-shell-command \"~/Projects/System/scripts/voice-dictate.scm\"))"
            #~"(defcommand zen () ()"
            #~"  \"Toggle distraction-free mode: flip gaps and the mode line together.\""
            #~"  (swm-gaps:toggle-gaps)"
            #~"  (dolist (h (screen-heads (current-screen)))"
            #~"    (toggle-mode-line (current-screen) h)))"
            #~"(defcommand next-wallpaper () ()"
            #~"  \"Reshuffle the desktop wallpaper from ~/Projects/images.\""
            #~"  (run-shell-command \"feh --no-fehbg --bg-fill --randomize ~/Projects/images/*\")"
            #~"  (message \"^2*wallpaper reshuffled\"))"
            #~";; AI oracle (backed by scripts/ask-ai.scm — needs ANTHROPIC_API_KEY)"
            #~"(defun sh-quote (s)"
            #~"  (let ((q (string #\\')) (esc (coerce (list #\\' #\\\\ #\\' #\\') 'string)))"
            #~"    (concatenate 'string q"
            #~"      (with-output-to-string (o)"
            #~"        (loop for c across s do"
            #~"          (if (char= c #\\') (write-string esc o) (write-char c o))))"
            #~"      q)))"
            #~"(defcommand ask-ai (q) ((:string \"Ask AI: \"))"
            #~"  \"Ask Claude a one-shot question; show the answer as a centered message.\""
            #~"  (when (plusp (length q))"
            #~"    (message \"^5*thinking...\")"
            #~"    (let ((ans (run-shell-command"
            #~"                 (concatenate 'string"
            #~"                   (getenv \"HOME\") \"/Projects/System/scripts/ask-ai.scm \""
            #~"                   (sh-quote q))"
            #~"                 t)))"
            #~"      (message \"^7*~a\" (string-trim '(#\\Space #\\Newline #\\Return) ans)))))"
            #~"(defcommand ai-clipboard () ()"
            #~"  \"Improve the X selection with Claude and put the result on the clipboard.\""
            #~"  (let ((sel (run-shell-command \"xsel -o -b\" t)))"
            #~"    (if (plusp (length (string-trim '(#\\Space #\\Newline #\\Return) sel)))"
            #~"        (progn"
            #~"          (message \"^5*rewriting selection...\")"
            #~"          (let ((ans (string-trim '(#\\Space #\\Newline #\\Return)"
            #~"                       (run-shell-command"
            #~"                         (concatenate 'string"
            #~"                           \"ASK_AI_SYSTEM='You are a copy editor. Improve grammar, clarity and flow. Keep the meaning and the original language. Output only the revised text.' \""
            #~"                           (getenv \"HOME\") \"/Projects/System/scripts/ask-ai.scm \""
            #~"                           (sh-quote sel))"
            #~"                         t))))"
            #~"            (run-shell-command"
            #~"              (concatenate 'string \"printf %s \" (sh-quote ans) \" | xsel -i -b\") nil)"
            #~"            (message \"^2*clipboard updated (~a chars)\" (length ans))))"
            #~"        (message \"^1*clipboard empty\"))))"
            #~";; Init"
            #~"(when *initializing*"
            #~"      (run-shell-command \"picom -b\")"
            #~"      (run-shell-command \"xss-lock --transfer-sleep-lock -- ~/Projects/System/scripts/lock-screen.scm &\")"
            #~"      (run-shell-command \"feh --no-fehbg --bg-fill --randomize ~/Projects/images/*\")"
	    #~"      (run-shell-command \"if [ $(hostname) = 'T450s' ]; then setxkbmap de bone; fi\")"
            #~"      (mode-line)"
            #~"      (dolist (h (screen-heads (current-screen)))"   
            #~"        (enable-mode-line (current-screen) h t))"
            #~"      (swm-gaps:toggle-gaps))"))
          (setf-entries
           (list
            ;; Mode line padding and format (no color settings here)
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
               (stumpwm-keybinding (key "Return") (command "exec alacritty"))
               (stumpwm-keybinding (key "a") (command "ask-ai"))
               (stumpwm-keybinding (key "b") (command "exec nyxt"))
               (stumpwm-keybinding (key "e") (command "exec lem -i sdl2"))
               (stumpwm-keybinding (key "E") (command "exec emacsclient -c"))
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
               (stumpwm-keybinding (key "D") (command "dashboard"))
               (stumpwm-keybinding (key "t") (command "terminal-dashboard"))
               (stumpwm-keybinding (key "T") (command "add-todo"))
               (stumpwm-keybinding (key "w") (command "voice-dictate"))
               (stumpwm-keybinding (key "z") (command "zen")))))
            
            ;; Screenshot map
            (stumpwm-keymap
             (name "screenshot")
             (prefix-key "S")
             (bindings
              (list
               (stumpwm-keybinding (key ".") (command "exec spectacle"))
               (stumpwm-keybinding (key ",") (command "get-latex")))))

            ;; Agent launcher map
            (stumpwm-keymap
             (name "agents")
             (prefix-key "A")
             (bindings
              (list
               (stumpwm-keybinding (key "c") (command "codex-agent"))
               (stumpwm-keybinding (key "d") (command "claude-agent"))
               (stumpwm-keybinding (key "o") (command "opencode-agent"))
               (stumpwm-keybinding (key "p") (command "pi-agent")))))
            
            ;; Misc map
            (stumpwm-keymap
             (name "misc")
             (map-variable "*misc-map*")
             (prefix-key "P")
             (bindings
              (list
               (stumpwm-keybinding (key "s") (command "browser-search"))
               (stumpwm-keybinding (key "w") (command "next-wallpaper"))
               (stumpwm-keybinding (key "a") (command "ai-clipboard"))
               ;;(stumpwm-keybinding (key "i") (command "internet-10-min"))
               ;;(stumpwm-keybinding (key "t") (run-shell-command "date "+%Y-%m-%d" | xsel --clipboard --input"))
               ))))))))
