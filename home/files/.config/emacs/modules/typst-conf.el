;;; typst-conf.el --- Typst editing and live preview -*- lexical-binding: t -*-
;;; Code:

;; typst-ts-mode registers itself for .typ files; its grammar
;; (tree-sitter-typst) is found through the Guix grammar directories that
;; python-conf adds to `treesit-extra-load-path'.

;; ── Live preview ──────────────────────────────────────────────────────────────
;;
;; typst-preview.el runs `tinymist preview' (tinymist-bin) and opens it in the
;; browser.  tinymist-bin embeds the same Typst version as typst-bin, so the
;; preview matches the compiled PDF.

(setq typst-preview-ask-if-pin-main nil)   ; never write local variables into sources

(defvar-local sls-typst-font-paths nil
  "Font directories, relative to the project root, passed to the preview.
Set per project in .dir-locals.el.")
(put 'sls-typst-font-paths 'safe-local-variable
     (lambda (v) (and (listp v) (seq-every-p #'stringp v))))

(defun sls-typst--preview-setup ()
  "Preview the nearest main.typ, rooted at the project root."
  (let ((root (if-let* ((project (project-current)))
                  (expand-file-name (project-root project))
                default-directory)))
    (setq-local typst-preview-default-dir root)
    (when-let* ((dir (locate-dominating-file default-directory "main.typ")))
      (setq-local typst-preview--master-file
                  (file-truename (expand-file-name "main.typ" dir))))
    (setq-local typst-preview-cmd-options
                (mapcan (lambda (d) (list "--font-path" (expand-file-name d root)))
                        sls-typst-font-paths))))

(defun sls-typst-preview ()
  "Toggle the browser preview of the nearest main.typ."
  (interactive)
  (if (bound-and-true-p typst-preview-mode)
      (typst-preview-mode -1)
    (sls-typst--preview-setup)
    (typst-preview-mode 1)))

(provide 'typst-conf)
;;; typst-conf.el ends here
