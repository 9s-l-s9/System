(provide 'cpp-config)

(defvar regular-emacs-state nil "State variable to toggle between regular and minimalist Emacs look.")

(defun toggle-regular-emacs-look ()
  "Toggle between regular and minimalist Emacs look."
  (interactive)
  (if regular-emacs-state
      (progn
        ;; Set up minimalist look
        (tool-bar-mode -1)
        (menu-bar-mode -1)
        (scroll-bar-mode -1)
        ;; Set up your special modeline here
        ;; ...
        (setq regular-emacs-state nil))
    (progn
      ;; Set up regular Emacs look
      (tool-bar-mode 1)
      (menu-bar-mode 1)
      (scroll-bar-mode 1)
      ;; Set up regular modeline here
      ;; ...
      (setq regular-emacs-state t))))

(defun my-cpp-debug ()
  "Compile the current file with g++ and debug it with GDB in Emacs."
  (interactive)
  (let ((file-name (buffer-file-name))
        (exec-name (file-name-sans-extension (buffer-file-name)))
        (compile-command "g++ -g -o "))
    (if file-name
        (progn
          ;; Toggle to regular Emacs look
          (toggle-regular-emacs-look)
          ;; Compile the current file
          (shell-command (concat compile-command exec-name " " file-name))
          ;; Start GDB
          (gdb (concat "gdb -i=mi " exec-name))
          ;; Set up multi-window GDB layout
          (gdb-many-windows))
      (message "Buffer is not visiting a file!"))))
