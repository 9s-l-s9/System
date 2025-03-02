(defcommand browser-search (search-term) ((:string "Search: "))
  "Prompt for search term and open it in the default browser"
  (run-shell-command 
    (concatenate 'string 
                 "xdg-open 'https://www.google.com/search?q="
                 (string-trim " " search-term)
                 "'")))




(defun toggle-internet ()
  "Toggle Wi-Fi on or off. Needs nmcli."
  (let ((status (uiop:run-program '("nmcli" "-t" "-f" "WIFI" "radio") :output :string)))
    (if (string= (string-trim '(#\Newline #\Return) status) "enabled")
        (run-shell-command "nmcli radio wifi off")
        (run-shell-command "nmcli radio wifi on"))))

(defun toggle-internet-after-delay (delay)
  "Turn off the internet after a specified delay."
  (run-with-timer delay nil  ;; `delay` is the time in seconds
                  (lambda ()
                    (toggle-internet))))

(defcommand internet-10-min () ()
  "Turn on the internet but only for 10 minutes to do a quick task."
  (progn
    (toggle-internet)                ;; Turn on the internet
    (toggle-internet-after-delay 600)))  ;; Schedule turning it off after 600 seconds
