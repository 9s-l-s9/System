
(in-package :lem-user)

(load-theme "chalk")

(defvar *sls-main-keymap*
  (make-keymap :name '*sls-main-keymap*)
  "Private keymap.")

(define-key *sls-main-keymap* "b" 'describe-bindings)
(define-key *sls-main-keymap* "f" 'find-file)
(define-key *sls-main-keymap* "q" 'execute-command)
(define-key *sls-main-keymap* "d" 'delete-active-window)
(define-key *sls-main-keymap* "o" 'lem-core/commands/file:find-file-recursively)

(define-key *global-keymap* "F12" *sls-main-keymap*)



;; Set the default package to LEM
(lem-lisp-mode/internal::lisp-set-package "LEM")

;; Grep
(defvar *rgrep-command* "ag -Q -U -W 300 -m 1000 --vimgrep ")

(define-command rgrep () ()
  (let* ((default (symbol-string-at-point (lem:current-point)))
         (search (prompt-for-string "Grep: " :initial-value default))
         (directory (prompt-for-directory "Directory: "
                                          :directory (buffer-directory))))
    (lem/grep:grep (str:concat *rgrep-command* search) directory)))

; Trailing spacesx
(add-hook (variable-value 'before-save-hook :global t)
          'delete-trailing-whitespace)

