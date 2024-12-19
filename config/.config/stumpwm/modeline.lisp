(defun show-username-at-host-formatter ()
  "Retrieve and format the current user's UNIX name, followed by a @ and %h for
   use with the hostname StumpWM module.

  Returns:
    STRING: The UNIX name of the current user, or '^Rnil^r' if unavailable, followed by a @,
            and the literal string %h

  Example:
    for the username \"alice\", this would return:
       \"alice@%h\""
  (let* ((username (run-shell-command-and-format "whoami"))
         (at-symbol "@")
         (hostname-formatter "%h"))
    (if (string-equal username "")
        "^Rnil^r"
        (format nil "~A~A~A" username at-symbol hostname-formatter))))

(defun show-window-title ()
  "Retrieve and format the title of the currently active window.

  Returns:
    STRING: The title of the current window, or '^Rnil^r' if no window is active.

  This function gets the title of the current window, normalizes it,
  and handles the case where there is no active window."
  (normalize-and-handle-empty (window-title (current-window))))

;; Constants
(defparameter pipe " | ")
(defparameter host-bracket-color "^4") ;; Soft Blue
(defparameter host-content-color "^3") ;; Soft Yellow
(defparameter name-bracket-color "^6") ;; Soft Aqua
(defparameter name-content-color "^7") ;; White
(defparameter group-bracket-color "^7") ;; White
(defparameter group-content-color "^6") ;; Soft Aqua
(defparameter audio-bracket-color "^8") ;; Soft Orange
(defparameter audio-content-color "^B^2*^b") ;; Soft Green
(defparameter status-bracket-color "^5") ;; Soft Magenta
(defparameter status-content-color "^3*") ;; Soft Yellow
(defparameter win-bracket-color "^1") ;; Soft Red
(defparameter win-content-color "^2" ) ;; Soft Green

;; Components
(defvar host-fmt (list
                  '(:eval (show-username-at-host-formatter))))
(defvar group-fmt "%g") ;; Group ID's
(defvar name-fmt "%n=> %W") ;; Group name => Window ID's
(defvar status-fmt (list
                    '(:eval (if (battery-present-p)
                                (concatenate 'string "%B" pipe)
                                "")) ;; Battery
		    "^>"
                    "%d" ;; Date
                    ))

;; Generate a Component of a given color
(defun generate-mode-line-component (out-color in-color component &optional right-alignment)
  "Generate a colored component for the mode line.

  Arguments:
    OUT-COLOR: String representing the color for brackets.
    IN-COLOR: String representing the color for the component content.
    COMPONENT: The content to be displayed in the component.
    RIGHT-ALIGNMENT: If non-nil, the component will be right-aligned.

  Returns:
    LIST: A list representing the formatted mode line component.

  This function creates a formatted component for the mode line with specified colors
  and optional right alignment.

  Example usage:
    (generate-mode-line-component \"^8\" \"^6\" \"%g\")

    This returns a LIST with:
      Outer bracket color: \"^8\"
      Content color: \"^6\"
      Format string: \"%g\"

    Returned list:
      (\"^8\" \"[\" \"^6\" \"%g\" \"^8\" \"]\")"
  (if right-alignment
      (list "^>" out-color "[" in-color component out-color "]")
      (list out-color "[" in-color component out-color "]")))

(defun generate-mode-line ()
  "Build and set the complete mode line format.

  This function constructs the mode line by combining various components
  with appropriate colors and formatting. It sets the *screen-mode-line-format*
  variable with the constructed mode line."
  (setf *screen-mode-line-format*
	(list
         (generate-mode-line-component host-bracket-color host-content-color host-fmt)
         (generate-mode-line-component group-bracket-color group-content-color group-fmt)
         (generate-mode-line-component name-bracket-color name-content-color name-fmt)
         (generate-mode-line-component status-bracket-color status-content-color status-fmt))))

;; Actually load my modeline
(generate-mode-line)

;; Format Modeline
(setf *mode-line-background-color* "#1D2021"
      *mode-line-border-color* "#EBDBB2"
      *mode-line-border-width* 3
      *mode-line-pad-x* 4
      *mode-line-pad-y* 6
      *mode-line-timeout* 15)

;; mode line on all heads
(dolist (h (screen-heads (current-screen)))
  (enable-mode-line (current-screen) h t))
