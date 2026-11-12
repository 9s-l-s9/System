;;; notmuch-conf.el --- Mail: notmuch over the Mailfence Maildir -*- lexical-binding: t -*-
;;; Code:

;; Mail is fetched by the mail-sync timer (home/services/mail.scm); Emacs
;; only reads the notmuch index and sends through msmtp.

;; ── Icons ───────────────────────────────────────────────────────────────────
;; Nerd Font glyphs (font-nerd-symbols) on graphical frames; the one-letter
;; fallback keeps terminal frames and batch tests readable.

(defvar sls-notmuch-icons
  '((unread     "nf-md-email"                         "U")
    (read       "nf-md-email_open_outline"            "·")
    (flagged    "nf-md-flag"                          "!")
    (attachment "nf-md-paperclip"                     "@")
    (replied    "nf-md-reply"                         "r")
    (sent       "nf-md-send"                          ">")
    (draft      "nf-md-pencil"                        "d")
    (inbox      "nf-md-inbox"                         "i")
    (todo       "nf-md-checkbox_marked_circle_outline" "t")
    (later      "nf-md-clock_outline"                 "l")
    (wichtig    "nf-md-star"                          "*")
    (spam       "nf-md-alert_octagon_outline"         "x")
    (deleted    "nf-md-trash_can_outline"             "D"))
  "Mail states and tags as (NAME NERD-ICON FALLBACK).")

(defvar sls-notmuch-use-icons t
  "Render mail markers as Nerd Font glyphs on graphical frames.")

(defun sls-notmuch-icons-p ()
  "Whether icon glyphs can be rendered right now."
  (and sls-notmuch-use-icons (display-graphic-p) (require 'nerd-icons nil t)))

(defun sls-notmuch-icon (name &optional face)
  "Return the one-cell marker for state NAME in FACE, a blank when NAME is nil."
  (if-let* ((entry (alist-get name sls-notmuch-icons)))
      (let ((icon (copy-sequence (if (sls-notmuch-icons-p)
                                     (nerd-icons-mdicon (car entry))
                                   (cadr entry)))))
        (when face (add-face-text-property 0 (length icon) face nil icon))
        icon)
    " "))

(defun sls-notmuch-label (name &optional text)
  "Saved-search label TEXT (default NAME) with its icon in front.
Decided when the config loads: the daemon has no graphical frame yet, so
only the font's presence counts here."
  (let ((text (or text (symbol-name name))))
    (if (require 'nerd-icons nil t)
        (concat (nerd-icons-mdicon (car (alist-get name sls-notmuch-icons))) " " text)
      text)))

;; ── Result lines ────────────────────────────────────────────────────────────

(defun sls-notmuch-status (format-string result)
  "Render three markers for RESULT: unread/read, flagged, attachment/replied/sent.
Glyphs are not exactly one cell wide, so the column ends with a spacer
that pins the date column to the same place on every line."
  (let ((tags (plist-get result :tags)))
    (format format-string
            (concat (if (member "unread" tags)
                        (sls-notmuch-icon 'unread)
                      (sls-notmuch-icon 'read 'shadow))
                    " "
                    (sls-notmuch-icon (and (member "flagged" tags) 'flagged))
                    " "
                    (sls-notmuch-icon (cond ((member "attachment" tags) 'attachment)
                                            ((member "replied" tags) 'replied)
                                            ((member "sent" tags) 'sent)))
                    (propertize " " 'display '(space :align-to 7))))))

(defun sls-notmuch-tags-column (format-string result)
  "Tags of RESULT minus those the marker column shows or the search implies."
  (let* ((hidden (append '("unread" "flagged" "attachment" "replied")
                         (when (string-match-p "tag:inbox" (or notmuch-search-query-string ""))
                           '("inbox"))))
         (visible (lambda (tags) (seq-remove (lambda (tag) (member tag hidden)) tags)))
         (tags (plist-get result :tags)))
    (format format-string
            (notmuch-tag-format-tags (funcall visible tags)
                                     (funcall visible (or (plist-get result :orig-tags) tags))))))

(defun sls-notmuch-insert-header-p (part hide)
  "Show a part button only for attachments and for parts notmuch hides.
notmuch's default shows one for every part of a multipart mail, so each
HTML newsletter opened with [ multipart/alternative ] [ text/plain ]."
  (or hide
      (plist-get part :filename)
      (let ((type (notmuch-show-mime-type part)))
        (not (or (string-prefix-p "multipart/" type)
                 (string-prefix-p "text/" type))))))

;; ── Common application menu ─────────────────────────────────────────────────

(defun sls-notmuch-ui-setup ()
  "Identify the mail view and expose its actions through the common menu."
  (setq-local sls-ui-refresh-function #'notmuch-refresh-this-buffer
              sls-ui-actions '(("Search mail…" . notmuch-search)
                               ("Compose mail…" . notmuch-mua-new-mail)
                               ("Mail folders" . notmuch)
                               ("Mail folders in sidebar" . sls-notmuch-sidebar)))
  (pcase major-mode
    ('notmuch-hello-mode
     (setq-local sls-ui-title "Mail / folders"
                 header-line-format "Mail / folders"))
    ('notmuch-search-mode
     (setq-local sls-ui-title "Mail / results"
                 sls-ui-next-function #'notmuch-search-next-thread
                 sls-ui-previous-function #'notmuch-search-previous-thread
                 header-line-format
                 (list "Mail / results  "
                       '(:eval (replace-regexp-in-string
                                "%" "%%" notmuch-search-query-string))
                       (concat "   " (sls-notmuch-icon 'unread) " unread  "
                               (sls-notmuch-icon 'flagged) " flagged  "
                               (sls-notmuch-icon 'attachment) " attachment")))
     (setq-local sls-ui-actions
                 (append '(("Reply to sender…" . notmuch-search-reply-to-thread-sender)
                           ("Reply to all…" . notmuch-search-reply-to-thread)
                           ("Archive thread" . notmuch-search-archive-thread)
                           ("Quick tag…" . notmuch-tag-jump)
                           ("Change tags…" . notmuch-search-tag)
                           ("Filter results…" . notmuch-search-filter)) sls-ui-actions)))
    ('notmuch-show-mode
     (setq-local sls-ui-title "Mail / thread"
                 sls-ui-actions
                 (append '(("Reply to sender…" . notmuch-show-reply-sender)
                           ("Reply to all…" . notmuch-show-reply)
                           ("Archive thread" . notmuch-show-archive-thread)
                           ("Quick tag…" . notmuch-tag-jump)
                           ("Change tags…" . notmuch-show-tag)
                           ("Toggle message headers" . notmuch-show-toggle-visibility-headers)
                           ("Next message" . notmuch-show-next-message)
                           ("Previous message" . notmuch-show-previous-message)) sls-ui-actions)))
    ('notmuch-tree-mode
     (setq-local sls-ui-title "Mail / tree"
                 header-line-format "Mail / tree"
                 sls-ui-actions
                 (append '(("Quick tag…" . notmuch-tag-jump)
                           ("Change tags…" . notmuch-tree-tag)
                           ("Archive thread" . notmuch-tree-archive-thread)) sls-ui-actions)))
    ('notmuch-message-mode
     (setq-local sls-ui-title "Mail / compose"
                 header-line-format "Mail / compose"
                 sls-ui-refresh-function nil
                 sls-ui-actions '(("Send message" . message-send-and-exit)
                                  ("Save draft" . notmuch-draft-save)
                                  ("Attach file…" . mml-attach-file))))))

(defun sls-notmuch-sidebar ()
  "Show the mail dashboard in the shared sidebar."
  (interactive)
  (require 'notmuch)
  (save-window-excursion (notmuch))
  (with-current-buffer "*notmuch-hello*" (setq-local sls-side-panel-p t))
  (sls-side-panel-show (get-buffer "*notmuch-hello*"))
  ;; Saved-search layout depends on the actual panel width.
  (notmuch-refresh-this-buffer)
  (when (fboundp 'sls-install-header-line) (sls-install-header-line)))

(dolist (hook '(notmuch-hello-mode-hook notmuch-search-mode-hook
                notmuch-show-mode-hook notmuch-tree-mode-hook notmuch-message-mode-hook))
  (add-hook hook #'sls-notmuch-ui-setup))

;; ── notmuch ─────────────────────────────────────────────────────────────────

(use-package notmuch
  :commands (notmuch notmuch-search notmuch-mua-new-mail)
  :config
  (setq notmuch-show-logo nil
        notmuch-hello-sections '(notmuch-hello-insert-saved-searches)
        notmuch-column-control 1.0
        notmuch-show-empty-saved-searches t
        notmuch-show-header-line "Mail / thread   %s"
        notmuch-message-headers '("Subject" "From" "To" "Cc" "Date")
        ;; The summary line already names sender, date and tags; `h' shows
        ;; the full header block of a message when it matters.
        notmuch-message-headers-visible nil
        ;; Part buttons only for attachments (see `sls-notmuch-insert-header-p').
        notmuch-show-insert-header-p-function #'sls-notmuch-insert-header-p
        ;; Plain-text bodies wrap at a reading width instead of the window edge.
        notmuch-wash-wrap-lines-length 100
        notmuch-search-result-format
        '((sls-notmuch-status . "%s")
          ("date" . "%12s  ") ("authors" . "%-22s  ")
          ("count" . "%-7s  ") ("subject" . "%s  ") (sls-notmuch-tags-column . "%s"))
        ;; States and folders become icons, work tags stay words.  notmuch
        ;; caches these per tag, so they must not depend on the buffer; the
        ;; result list drops the ones its marker column shows.  `tag' is
        ;; bound while a format is evaluated.
        notmuch-tag-formats
        '(("unread" (sls-notmuch-icon 'unread))
          ("flagged" (sls-notmuch-icon 'flagged))
          ("attachment" (sls-notmuch-icon 'attachment 'shadow))
          ("replied" (sls-notmuch-icon 'replied 'shadow))
          ("inbox" (sls-notmuch-icon 'inbox 'shadow))
          ("sent" (sls-notmuch-icon 'sent 'shadow))
          ("draft" (sls-notmuch-icon 'draft))
          ("signed")
          ("todo" (notmuch-apply-face tag 'warning))
          ("spam" (notmuch-apply-face tag 'shadow))
          ("deleted" (notmuch-apply-face tag 'shadow)))
        notmuch-show-all-multipart/alternative-parts nil
        ;; Quick tagging menu (K in every mail view; C-u K reverses).
        notmuch-tagging-keys
        `((,(kbd "a") notmuch-archive-tags "Archive")
          (,(kbd "u") notmuch-show-mark-read-tags "Mark read")
          (,(kbd "U") ("+unread") "Mark unread")
          (,(kbd "f") ("+flagged") "Flag")
          (,(kbd "t") ("+todo") "To do")
          (,(kbd "l") ("+later") "Later")
          (,(kbd "s") ("+spam" "-inbox") "Spam")
          (,(kbd "d") ("+deleted" "-inbox") "Delete"))
        notmuch-saved-searches
        `((:name ,(sls-notmuch-label 'inbox)   :query "tag:inbox"  :key "i")
          (:name ,(sls-notmuch-label 'unread)  :query "tag:unread" :key "u")
          (:name ,(sls-notmuch-label 'todo)    :query "tag:todo"   :key "t")
          (:name ,(sls-notmuch-label 'later)   :query "tag:later"  :key "l")
          (:name ,(sls-notmuch-label 'sent)    :query "tag:sent"   :key "s")
          (:name ,(sls-notmuch-label 'draft "drafts") :query "tag:draft" :key "d")
          (:name ,(sls-notmuch-label 'wichtig) :query "folder:Wichtig" :key "w")
          ;; tag:spam is excluded from other searches; job mail often lands here.
          (:name ,(sls-notmuch-label 'spam)    :query "tag:spam"   :key "x"))
        ;; Postponed drafts go to the synced Drafts folder, so they also
        ;; appear in the Mailfence web UI.
        notmuch-draft-folder "Drafts"
        ;; Mailfence keeps no SMTP copy. notmuch insert files and indexes our
        ;; copy; mailfence-sent uploads it on the next Sync Pull PushNew run.
        notmuch-fcc-dirs "\"Sent Items\" +sent -draft -unread -inbox")
  ;; Buffer-local variable: `setq' here only set it in whichever buffer was
  ;; current while notmuch loaded, so searches stayed oldest-first.
  (setq-default notmuch-search-oldest-first nil)
  ;; Semantic inheritance remains legible with both light and dark themes.
  ;; Line faces (unread, flagged) must not inherit `default': that would
  ;; carry its font family over the icon glyphs and the tag faces on
  ;; those lines.
  (custom-set-faces
   '(notmuch-search-unread-face ((t (:weight bold))))
   '(notmuch-search-flagged-face ((t (:foreground unspecified :weight bold))))
   '(notmuch-search-date ((t (:foreground unspecified :inherit shadow))))
   '(notmuch-search-count ((t (:foreground unspecified :inherit shadow))))
   '(notmuch-search-matching-authors ((t (:foreground unspecified :inherit default))))
   '(notmuch-search-non-matching-authors ((t (:foreground unspecified :inherit shadow))))
   '(notmuch-search-subject ((t (:foreground unspecified :inherit default))))
   '(notmuch-tag-face ((t (:foreground unspecified :inherit shadow))))
   '(notmuch-message-summary-face ((t (:inherit secondary-selection :weight bold :extend t))))))

(with-eval-after-load 'message
  (setq message-send-mail-function #'message-send-mail-with-sendmail
        sendmail-program "msmtp"
        message-sendmail-envelope-from 'header
        mail-specify-envelope-from t
        mail-envelope-from 'header
        message-kill-buffer-on-exit t))

(provide 'notmuch-conf)
;;; notmuch-conf.el ends here
