;;; notmuch-conf.el --- Mail: notmuch over the Mailfence Maildir -*- lexical-binding: t -*-
;;; Code:

;; Mail is fetched by the mail-sync timer (home/services/mail.scm); Emacs
;; only reads the notmuch index and sends through msmtp.

(defun sls-notmuch-status (format-string result)
  "Render explicit unread/flagged indicators for RESULT."
  (let ((tags (plist-get result :tags)))
    (format format-string (concat (if (member "unread" tags) "U" "·")
                                  (if (member "flagged" tags) "!" " ")))))

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
                 '("Mail / results  " (:eval (replace-regexp-in-string
                                                "%" "%%" notmuch-search-query-string))
                   "   · U unread / ! flagged"))
     (setq-local sls-ui-actions
                 (append '(("Reply to sender…" . notmuch-search-reply-to-thread-sender)
                           ("Reply to all…" . notmuch-search-reply-to-thread)
                           ("Archive thread" . notmuch-search-archive-thread)
                           ("Change tags…" . notmuch-search-tag)
                           ("Filter results…" . notmuch-search-filter)) sls-ui-actions)))
    ('notmuch-show-mode
     (setq-local sls-ui-title "Mail / thread"
                 sls-ui-actions
                 (append '(("Reply to sender…" . notmuch-show-reply-sender)
                           ("Reply to all…" . notmuch-show-reply)
                           ("Archive thread" . notmuch-show-archive-thread)
                           ("Change tags…" . notmuch-show-tag)
                           ("Toggle message headers" . notmuch-show-toggle-visibility-headers)
                           ("Next message" . notmuch-show-next-message)
                           ("Previous message" . notmuch-show-previous-message)) sls-ui-actions)))
    ('notmuch-tree-mode
     (setq-local sls-ui-title "Mail / tree"
                 header-line-format "Mail / tree"
                 sls-ui-actions
                 (append '(("Change tags…" . notmuch-tree-tag)
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

(use-package notmuch
  :commands (notmuch notmuch-search notmuch-mua-new-mail)
  :config
  (setq notmuch-show-logo nil
        notmuch-hello-sections '(notmuch-hello-insert-saved-searches)
        notmuch-column-control 1.0
        notmuch-show-empty-saved-searches t
        ;; Plain tag names; unread/flagged already have explicit row markers.
        notmuch-tag-formats nil
        notmuch-search-oldest-first nil
        notmuch-show-header-line "Mail / thread   %s"
        notmuch-message-headers '("Subject" "From" "To" "Cc" "Date")
        notmuch-message-headers-visible t
        notmuch-search-result-format
        '((sls-notmuch-status . "%-2s ")
          ("date" . "%12s  ") ("authors" . "%-22s  ")
          ("count" . "%-7s  ") ("subject" . "%s  ") ("tags" . "(%s)"))
        notmuch-show-all-multipart/alternative-parts nil
        notmuch-saved-searches
        '((:name "inbox"   :query "tag:inbox"  :key "i")
          (:name "unread"  :query "tag:unread" :key "u")
          (:name "sent"    :query "tag:sent"   :key "s")
          (:name "drafts"  :query "tag:draft"  :key "d")
          (:name "wichtig" :query "folder:Wichtig" :key "w")
          ;; tag:spam is excluded from other searches; job mail often lands here.
          (:name "spam"    :query "tag:spam" :key "x"))
        ;; Postponed drafts go to the synced Drafts folder, so they also
        ;; appear in the Mailfence web UI.
        notmuch-draft-folder "Drafts"
        ;; Mailfence's SMTP relay may already file a copy in Sent Items;
        ;; enable a local Fcc only if sent mail turns out to be missing there.
        notmuch-fcc-dirs nil)
  ;; Semantic inheritance remains legible with both light and dark themes.
  (custom-set-faces
   '(notmuch-search-unread-face ((t (:weight bold))))
   '(notmuch-search-flagged-face ((t (:foreground unspecified :inherit default :weight bold))))
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
