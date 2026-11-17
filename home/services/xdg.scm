(define-module (services xdg)
  #:use-module (gnu home services xdg)
  #:use-module (gnu services)
  #:export (xdg-services))

;; XDG user directories and default applications, declared instead of the
;; files that xdg-user-dirs-update and "Open with ... always" used to write
;; into ~/.config.  Guix Home installs both files read-only, so a desktop's
;; "remember this choice" no longer sticks: change the defaults here.

;; Desktop, Pictures, Templates, Public and Videos stay the home directory
;; itself; the activation would otherwise create empty folders.
(define %user-directories
  (home-xdg-user-directories-configuration
   (desktop "$HOME")
   (documents "$HOME/Documents")
   (download "$HOME/Downloads")
   (music "$HOME/Music")
   (pictures "$HOME")
   (publicshare "$HOME")
   (templates "$HOME")
   (videos "$HOME")))

;; Zen is the browser and PDF viewer.  claude-cli is the URL scheme Claude
;; Code's browser login returns to; its desktop entry is installed by Claude
;; Code itself in ~/.local/share/applications.
(define %default-applications
  (home-xdg-mime-applications-configuration
   (default
     '((text/html . zen.desktop)
       (application/xhtml+xml . zen.desktop)
       (application/pdf . zen.desktop)
       (x-scheme-handler/http . zen.desktop)
       (x-scheme-handler/https . zen.desktop)
       (x-scheme-handler/claude-cli . claude-code-url-handler.desktop)))))

(define (xdg-services)
  (list (service home-xdg-user-directories-service-type %user-directories)
        (service home-xdg-mime-applications-service-type
                 %default-applications)))
