;;; notmuch-conf.el --- Mail: notmuch over the Mailfence Maildir -*- lexical-binding: t -*-
;;; Code:

;; Mail is fetched by the mail-sync timer (home/services/mail.scm); Emacs
;; only reads the notmuch index and sends through msmtp.

(use-package notmuch
  :commands (notmuch notmuch-search notmuch-mua-new-mail)
  :config
  (setq notmuch-show-logo nil
        notmuch-search-oldest-first nil
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
        notmuch-fcc-dirs nil))

(with-eval-after-load 'message
  (setq message-send-mail-function #'message-send-mail-with-sendmail
        sendmail-program "msmtp"
        message-sendmail-envelope-from 'header
        mail-specify-envelope-from t
        mail-envelope-from 'header
        message-kill-buffer-on-exit t))

(provide 'notmuch-conf)
;;; notmuch-conf.el ends here
