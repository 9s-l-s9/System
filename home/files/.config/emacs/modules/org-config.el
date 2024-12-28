(provide 'org-config)

;; Always display images
(setq org-startup-with-inline-images t)

;; HTML export
;; Load the publishing system
(add-to-list 'load-path "~/Projects/org-html-themify")

(setq org-startup-indented t
      org-pretty-entities t
      ;; show actually italicized text instead of /italicized text/
      org-hide-emphasis-markers t
      org-agenda-block-separator ""
      org-fontify-whole-heading-line t
      org-fontify-done-headline t
      org-fontify-quote-and-verse-blocks t)




(require 'org-html-themify)

(setq org-html-themify-themes
      '((dark . doom-oceanic-next)
        (light . modus-operandi)))

(add-hook 'org-mode-hook 'org-html-themify-mode)
(require 'htmlize)
(require 'ox-publish)

      ;;   ;; Customize the HTML output
      ;;   (setq org-html-validation-link nil            ;; Don't show validation link
      ;;         org-html-head-include-scripts nil       ;; Use our own scripts
      ;;         org-html-head-include-default-style nil ;; Use our own styles
      ;; org-html-head "<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\" />")

              ;org-html-head "<link href=\"https://taopeng.me/org-notes-style/css/notes.css\" rel=\"stylesheet\" type=\"text/css\" />")


         ;; Define the publishing project
        (setq org-publish-project-alist
              (list
               (list "org-site:main"
                     :recursive t
                     :base-directory "./content"
                     :publishing-function 'org-html-publish-to-html
                     :publishing-directory "./public"
                     :with-author nil           ;; Don't include author name
                     :with-creator t            ;; Include Emacs and Org versions in footer
                     :with-toc t                ;; Include a table of contents
                     :section-numbers nil       ;; Don't include section numbers
                     :time-stamp-file nil)))    ;; Don't include time stamp in file

        ;; Generate the site output
        (org-publish-all t)
