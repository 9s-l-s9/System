#!/usr/bin/env guile
!#
;;; DRAFT! Pleaso do not use this yet

;;; git-sync
;;;
;;; synchronize tracking repositories
;;;
;;; 2012-20 by Simon Thum and contributors
;;; 2025 Guile Scheme port by Samuel Levi Schmidt
;;; Licensed as: CC0
;;;
;;; This script intends to sync via git near-automatically
;;; in "tracking" repositories where a nice history is not
;;; crucial, but having one at all is.

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 format)
             (srfi srfi-1))  ; For list operations

;; Default commit message 
(define DEFAULT-AUTOCOMMIT-MSG 
  (string-append "changes from " (uname 'nodename) " on " (strftime "%c" (localtime (current-time)))))

;; Command templates for auto-committing
(define DEFAULT-AUTOCOMMIT-CMD "git add -u ; git commit -m \"%message\";")
(define ALL-AUTOCOMMIT-CMD "git add -A ; git commit -m \"%message\";")

;; Global variables to store command line options
(define sync-new-files-anyway #f)
(define sync-anyway #f)
(define mode "sync")

;; Execute a shell command and return its output as a string
(define (exec-command cmd)
  (let* ((port (open-input-pipe cmd))
         (output (read-string port)))
    (close-pipe port)
    (string-trim-right output #\newline)))

;; Execute a shell command and return its exit status
(define (exec-command-status cmd)
  (let ((status (system cmd)))
    (status:exit-val status)))

;; Log a message
(define (log-msg message)
  (format #t "git-sync: ~a~%" message))

;; Get the git directory
(define (gitdir)
  (if (string=? "true" (exec-command "git rev-parse --is-inside-work-tree 2>/dev/null | head -1"))
      (exec-command "git rev-parse --git-dir 2>/dev/null")
      #f))

;; Get repository state
(define (git-repo-state)
  (let ((g (gitdir)))
    (if (not g)
        "NOGIT"
        (let ((state ""))
          ;; Check various special states
          (cond
           ((file-exists? (string-append g "/rebase-merge/interactive"))
            (set! state "REBASE-i"))
           ((file-exists? (string-append g "/rebase-merge"))
            (set! state "REBASE-m"))
           ((file-exists? (string-append g "/rebase-apply"))
            (set! state "AM/REBASE"))
           ((file-exists? (string-append g "/MERGE_HEAD"))
            (set! state "MERGING"))
           ((file-exists? (string-append g "/CHERRY_PICK_HEAD"))
            (set! state "CHERRY-PICKING"))
           ((file-exists? (string-append g "/BISECT_LOG"))
            (set! state "BISECTING")))
          
          ;; Check if inside git directory
          (if (string=? "true" (exec-command "git rev-parse --is-inside-git-dir 2>/dev/null"))
              (if (string=? "true" (exec-command "git rev-parse --is-bare-repository 2>/dev/null"))
                  (set! state (string-append state "|BARE"))
                  (set! state (string-append state "|GIT_DIR")))
              (if (string=? "true" (exec-command "git rev-parse --is-inside-work-tree 2>/dev/null"))
                  (if (not (= 0 (exec-command-status "git diff --no-ext-diff --quiet --exit-code")))
                      (set! state (string-append state "|DIRTY")))))
          
          (if (string=? state "")
              state  ; Return empty string if no special state
              state)))))

;; Check if we only have untouched, modified or (if configured) new files
(define (check-initial-file-state branch-name)
  (let ((sync-new (exec-command (string-append "git config --get --bool branch." branch-name ".syncNewFiles"))))
    (if (or (string=? "true" sync-new) sync-new-files-anyway)
        ;; Allow for new files
        (if (not (string=? "" (exec-command "git status --porcelain | grep -E '^[^ \\?][^M\\?] *'")))
            "NonNewOrModified"
            "")
        ;; Also bail on new files
        (if (not (string=? "" (exec-command "git status --porcelain | grep -E '^[^ ][^M] *'")))
            "NotOnlyModified"
            ""))))

;; Look for local changes
(define (local-changes)
  (if (not (string=? "" (exec-command "git status --porcelain | grep -E '^(\\?\\?|[MARC] |[ MARC][MD])*'")))
      "LocalChanges"
      ""))

;; Determine sync state of repository
(define (sync-state remote-name branch-name)
  (let ((count (exec-command (string-append "git rev-list --count --left-right " 
                                            remote-name "/" branch-name "...HEAD"))))
    (cond
     ((string=? "" count) "noUpstream")
     ((string=? "0\t0" count) "equal")
     ((string-match "^0\t" count) "ahead")
     ((string-match "^\t0$" count) "behind")
     (else "diverged"))))

;; Exit, issue warning if not in sync
(define (exit-assuming-sync remote-name branch-name)
  (if (string=? "equal" (sync-state remote-name branch-name))
      (begin
        (log-msg "In sync, all fine.")
        (exit 0))
      (begin
        (log-msg "Synchronization FAILED! You should definitely check your repository carefully!")
        (log-msg "(Possibly a transient network problem? Please try again in that case.)")
        (exit 3))))

;; Print usage information
(define (print-usage)
  (format #t "usage: ~a [-h] [-n] [-s] [MODE]~%" (car (command-line)))
  (display "Synchronize the current branch to a remote backup\n")
  (display "MODE may be either \"sync\" (the default) or \"check\", to verify that the branch is ready to sync\n")
  (display "OPTIONS:\n")
  (display "   -h      Show this message\n")
  (display "   -n      Commit new files even if branch.$branch_name.syncNewFiles isn't set\n")
  (display "   -s      Sync the branch even if branch.$branch_name.sync isn't set\n"))

;; Parse command line arguments
(define (parse-args args)
  (let loop ((args args))
    (if (null? args)
        '()
        (let ((arg (car args)))
          (cond
           ((string=? arg "-h")
            (print-usage)
            (exit 0))
           ((string=? arg "-n")
            (set! sync-new-files-anyway #t)
            (loop (cdr args)))
           ((string=? arg "-s")
            (set! sync-anyway #t)
            (loop (cdr args)))
           ((string=? arg "sync")
            (set! mode "sync")
            (loop (cdr args)))
           ((string=? arg "check")
            (set! mode "check")
            (loop (cdr args)))
           (else
            (if (string-prefix? "-" arg)
                (begin
                  (log-msg (string-append "Unknown option: " arg))
                  (print-usage)
                  (exit 1))
                (loop (cdr args)))))))))

;; Main function
(define (main)
  ;; Parse command line arguments
  (parse-args (cdr (command-line)))
  
  ;; First some sanity checks
  (let ((rstate (git-repo-state)))
    (cond
     ((or (string=? "" rstate) (string=? "|DIRTY" rstate))
      (log-msg (string-append "Preparing. Repo in " (gitdir))))
     ((string=? "NOGIT" rstate)
      (log-msg "No git repository detected. Exiting.")
      (exit 128))  ; Matches git's error code
     (else
      (log-msg (string-append "Git repo state considered unsafe for sync: " rstate))
      (exit 2))))
  
  ;; Determine the current branch
  (let ((branch-name (exec-command "git symbolic-ref -q HEAD | sed -e 's|^refs/heads/||'")))
    (if (string=? "" branch-name)
        (begin
          (log-msg "Syncing is only possible on a branch.")
          (system "git status")
          (exit 2)))
    
    ;; Determine the remote to operate on
    (let ((remote-name (exec-command (string-append "git config --get branch." branch-name ".pushRemote"))))
      (if (string=? "" remote-name)
          (set! remote-name (exec-command "git config --get remote.pushDefault")))
      (if (string=? "" remote-name)
          (set! remote-name (exec-command (string-append "git config --get branch." branch-name ".remote"))))
      
      (if (string=? "" remote-name)
          (begin
            (log-msg "the current branch does not have a configured remote.")
            (newline)
            (log-msg "Please use")
            (newline)
            (log-msg (string-append "  git branch --set-upstream-to=[remote_name]/" branch-name))
            (newline)
            (log-msg "replacing [remote_name] with the name of your remote, i.e. - origin")
            (log-msg "to set the remote tracking branch for git-sync to work")
            (exit 2)))
      
      ;; Check if current branch is configured for sync
      (if (and (not (string=? "true" (exec-command (string-append "git config --get --bool branch." branch-name ".sync"))))
               (not sync-anyway))
          (begin
            (newline)
            (log-msg "Please use")
            (newline)
            (log-msg (string-append "  git config --bool branch." branch-name ".sync true"))
            (newline)
            (log-msg (string-append "to enlist branch " branch-name " for synchronization."))
            (log-msg (string-append "Branch " branch-name " has to have a same-named remote branch"))
            (log-msg "for git-sync to work.")
            (newline)
            (log-msg "(If you don't know what this means, you should change that")
            (log-msg "before relying on this script. You have been warned.)")
            (newline)
            (exit 1)))
      
      ;; Log mode and remote information
      (log-msg (string-append "Mode " mode))
      (log-msg (string-append "Using " remote-name "/" branch-name))
      
      ;; Check for intentionally unhandled file states
      (let ((file-state (check-initial-file-state branch-name)))
        (if (not (string=? "" file-state))
            (begin
              (log-msg "There are changed files you should probably handle manually.")
              (system "git status")
              (exit 1))))
      
      ;; If in check mode, this is all we need to know
      (if (string=? mode "check")
          (begin
            (log-msg "check OK; sync may start.")
            (exit 0)))
      
      ;; Check if we have to commit local changes
      (let ((changes (local-changes)))
        (if (not (string=? "" changes))
            (let ((autocommit-cmd "")
                  (config-autocommit-cmd (exec-command (string-append "git config --get branch." branch-name ".autocommitscript"))))
              
              ;; Discern the three ways to auto-commit
              (if (not (string=? "" config-autocommit-cmd))
                  (set! autocommit-cmd config-autocommit-cmd)
                  (if (or (string=? "true" (exec-command (string-append "git config --get --bool branch." branch-name ".syncNewFiles")))
                          sync-new-files-anyway)
                      (set! autocommit-cmd ALL-AUTOCOMMIT-CMD)
                      (set! autocommit-cmd DEFAULT-AUTOCOMMIT-CMD)))
              
              (let ((commit-msg (exec-command (string-append "git config --get branch." branch-name ".syncCommitMsg"))))
                (if (string=? "" commit-msg)
                    (set! commit-msg DEFAULT-AUTOCOMMIT-MSG))
                
                ;; Replace %message with the actual commit message
                (set! autocommit-cmd (regexp-substitute/global #f "%message" autocommit-cmd 'pre commit-msg 'post))
                
                (log-msg (string-append "Committing local changes using " autocommit-cmd))
                (system autocommit-cmd)
                
                ;; After autocommit, we should be clean
                (let ((rstate (git-repo-state)))
                  (if (not (string=? "" rstate))
                      (begin
                        (log-msg "Auto-commit left uncommitted changes. Please add or remove them as desired and retry.")
                        (exit 1))))))))
      
      ;; Fetch remote to get to the current sync state
      (log-msg (string-append "Fetching from " remote-name "/" branch-name))
      (if (not (= 0 (exec-command-status (string-append "git fetch " remote-name " " branch-name))))
          (begin
            (log-msg (string-append "git fetch " remote-name " returned non-zero. Likely a network problem; exiting."))
            (exit 3)))
      
      ;; Handle different sync states
      (let ((current-state (sync-state remote-name branch-name)))
        (case (string->symbol current-state)
          ((noUpstream)
           (log-msg "Strange state, you're on your own. Good luck.")
           (exit 2))
          
          ((equal)
           (exit-assuming-sync remote-name branch-name))
          
          ((ahead)
           (log-msg "Pushing changes...")
           (if (= 0 (exec-command-status (string-append "git push " remote-name " " branch-name ":" branch-name)))
               (exit-assuming-sync remote-name branch-name)
               (begin
                 (log-msg "git push returned non-zero. Likely a connection failure.")
                 (exit 3))))
          
          ((behind)
           (log-msg "We are behind, fast-forwarding...")
           (if (= 0 (exec-command-status (string-append "git merge --ff --ff-only " remote-name "/" branch-name)))
               (exit-assuming-sync remote-name branch-name)
               (begin
                 (log-msg "git merge --ff --ff-only returned non-zero. Exiting.")
                 (exit 2))))
          
          ((diverged)
           (log-msg "We have diverged. Trying to rebase...")
           (if (and (= 0 (exec-command-status (string-append "git rebase " remote-name "/" branch-name)))
                    (string=? "" (git-repo-state))
                    (string=? "ahead" (sync-state remote-name branch-name)))
               (begin
                 (log-msg "Rebasing went fine, pushing...")
                 (system (string-append "git push " remote-name " " branch-name ":" branch-name))
                 (exit-assuming-sync remote-name branch-name))
               (begin
                 (log-msg "Rebasing failed, likely there are conflicting changes. Resolve them and finish the rebase before repeating git-sync.")
                 (exit 1)))))))))

(main)
