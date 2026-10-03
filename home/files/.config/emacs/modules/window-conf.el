;;; window-conf.el --- One reusable side panel -*- lexical-binding: t -*-
;;; Code:
(require 'cl-lib)

(defconst sls-side-panel-alist
  '((side . right) (slot . 0) (window-width . 0.32)
    (window-parameters . ((no-delete-other-windows . t)))))

(defvar-local sls-side-panel-p nil
  "Whether this buffer belongs in the shared sidebar.")

(defun sls-side-panel-buffer-p (buffer _action)
  "Match BUFFER by role, independently of its name."
  (with-current-buffer buffer
    (or sls-side-panel-p
        (derived-mode-p 'ibuffer-mode 'bookmark-bmenu-mode
                        'sls-recentf-mode 'sls-imenu-mode
                        'help-mode 'helpful-mode))))

(defun sls-display-side-panel (buffer alist)
  "Display BUFFER using ALIST and remember the main window it came from."
  (unless (window-parameter (selected-window) 'window-side)
    (set-frame-parameter nil 'sls-side-panel-origin (selected-window)))
  (display-buffer-in-side-window buffer (append alist sls-side-panel-alist)))

(add-to-list 'display-buffer-alist
             '(sls-side-panel-buffer-p sls-display-side-panel))

(defun sls-side-panel-window ()
  "Return the shared sidebar window on this frame."
  (cl-find-if (lambda (window)
                (and (eq (window-parameter window 'window-side) 'right)
                     (eq (window-parameter window 'window-slot) 0)))
              (window-list)))

(defun sls-main-window ()
  "Return a live non-side window on this frame."
  (or (and (not (window-parameter (selected-window) 'window-side))
           (selected-window))
      (let ((origin (frame-parameter nil 'sls-side-panel-origin)))
        (and (window-live-p origin)
             (eq (window-frame origin) (selected-frame))
             (not (window-parameter origin 'window-side)) origin))
      (cl-find-if (lambda (window) (not (window-parameter window 'window-side)))
                  (window-list))
      (user-error "No main window available")))

(defun sls-side-panel-show (buffer)
  "Display BUFFER in the shared sidebar and focus it."
  (let ((window (sls-display-side-panel buffer nil)))
    (unless (window-live-p window) (user-error "Cannot create sidebar on this frame"))
    (select-window window)))

(defun sls-side-panel-pin ()
  "Put the current buffer in the shared sidebar."
  (interactive)
  (let ((buffer (current-buffer)) (window (selected-window)))
    (setq-local sls-side-panel-p t)
    (sls-side-panel-show buffer)
    (unless (eq window (selected-window))
      (with-selected-window window (switch-to-prev-buffer window 'bury)))))

(defun sls-side-panel-select-buffer (buffer)
  "Select any BUFFER to display in the shared sidebar."
  (interactive (list (read-buffer "Sidebar buffer: " (other-buffer) t)))
  (with-current-buffer buffer (setq-local sls-side-panel-p t))
  (sls-side-panel-show buffer))

(defun sls-side-panel-pop-out ()
  "Move the sidebar's buffer into the main window."
  (interactive)
  (let ((panel (sls-side-panel-window)) (main (sls-main-window)))
    (unless panel (user-error "No sidebar is visible"))
    (let ((buffer (window-buffer panel)))
      (with-current-buffer buffer (setq-local sls-side-panel-p nil))
      (delete-window panel)
      (select-window main)
      (switch-to-buffer buffer))))

(defun sls-side-panel-focus ()
  "Move between the sidebar and the main window."
  (interactive)
  (if (window-parameter (selected-window) 'window-side)
      (select-window (sls-main-window))
    (let ((panel (sls-side-panel-window)))
      (unless panel (user-error "No sidebar is visible"))
      (set-frame-parameter nil 'sls-side-panel-origin (selected-window))
      (select-window panel))))

(defun sls-side-panel-hide ()
  "Hide the sidebar without killing its buffer."
  (interactive)
  (when-let* ((panel (sls-side-panel-window))) (delete-window panel)))

(defun sls-window-focus ()
  "Give the current view the whole frame, including when it is a panel."
  (interactive)
  (when (window-parameter (selected-window) 'window-side)
    (sls-side-panel-pop-out))
  (let ((ignore-window-parameters t)) (delete-other-windows)))

(defun sls-panel-visit-buffer (buffer &optional position)
  "Show destination BUFFER at POSITION in the main window."
  (select-window (sls-main-window))
  (switch-to-buffer buffer)
  (when position (goto-char position)))

(defun sls-bookmarks-open ()
  "Show bookmarks in the shared sidebar."
  (interactive)
  (require 'bookmark)
  (bookmark-bmenu-list)
  (sls-side-panel-show (get-buffer "*Bookmark List*")))

(defun sls-bookmark-open ()
  "Visit the bookmark at point in the main window."
  (interactive)
  (let ((bookmark (bookmark-bmenu-bookmark)))
    (select-window (sls-main-window))
    (bookmark-jump bookmark)))

(defun sls-ibuffer-open ()
  "Visit the buffer on the current Ibuffer row in the main window."
  (interactive)
  (let ((buffer (ibuffer-current-buffer t)))
    (unless buffer (user-error "No buffer on this row"))
    (sls-panel-visit-buffer buffer)))

(setq ibuffer-use-other-window t
      ibuffer-formats '((mark modified read-only " " (name 22 22 :left :elide)
                            " " (mode 12 12 :left :elide))))

(defun sls-ibuffer-prepare (&optional _other-window name &rest _)
  "Give Ibuffer's buffer a panel role before Ibuffer displays it.
Ibuffer sets its major mode only after choosing a window."
  (with-current-buffer (get-buffer-create (or name "*Ibuffer*"))
    (setq-local sls-side-panel-p t)))
(with-eval-after-load 'ibuffer
  (advice-add 'ibuffer :before #'sls-ibuffer-prepare))
(defun sls-ibuffer-setup ()
  (setq-local sls-ui-title "Buffers" sls-ui-open-function #'sls-ibuffer-open))
(defun sls-bookmark-setup ()
  (setq-local sls-ui-title "Bookmarks" sls-ui-open-function #'sls-bookmark-open))
(add-hook 'ibuffer-mode-hook #'sls-ibuffer-setup)
(add-hook 'bookmark-bmenu-mode-hook #'sls-bookmark-setup)

(provide 'window-conf)
;;; window-conf.el ends here
