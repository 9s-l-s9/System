#!/usr/bin/env guile
!#
;;; ask-ai.scm --- One-shot Claude query for StumpWM.
;;;
;;; A small desktop oracle: give it a prompt (as arguments, or on stdin) and it
;;; returns Claude's answer on stdout.  Bound in home/services/stumpwm.scm as the
;;; `ask-ai' (Print a) and `ai-clipboard' (Print P a) commands.
;;;
;;; Requires ANTHROPIC_API_KEY in the environment (the same key gptel reads).
;;; Tunables via env: ASK_AI_MODEL, ASK_AI_SYSTEM, ASK_AI_MAX_TOKENS.
;;;
;;; Guile-only per repo policy; like voice-dictate.scm it drives an external
;;; binary (curl, already in the Guix profile) rather than re-implementing TLS.

(use-modules (json)
             (ice-9 popen)
             (ice-9 textual-ports)
             (srfi srfi-13))

;; ── Configuration ──────────────────────────────────────────────────────────
(define api-key (getenv "ANTHROPIC_API_KEY"))

(define model (or (getenv "ASK_AI_MODEL") "claude-sonnet-4-5"))

(define max-tokens
  (or (and=> (getenv "ASK_AI_MAX_TOKENS") string->number) 1024))

(define system-prompt
  (or (getenv "ASK_AI_SYSTEM")
      (string-append
       "You are a terse desktop oracle for a GNU Guix / StumpWM power user. "
       "Answer in plain text, no markdown, at most ~5 short lines. "
       "Prefer exact commands or facts over prose. If unsure, say so briefly.")))

(define runtime-dir (or (getenv "XDG_RUNTIME_DIR") "/tmp"))
(define body-file (string-append runtime-dir "/ask-ai.json"))

(define (data-home)
  (or (getenv "XDG_DATA_HOME")
      (string-append (getenv "HOME") "/.local/share")))

;; Append-only Org transcript of every exchange.  Set ASK_AI_HISTORY to "" or
;; "none" to disable logging.
(define history-file
  (let ((override (getenv "ASK_AI_HISTORY")))
    (cond
     ((and override (member override '("" "none" "off"))) #f)
     ((and override (not (string-null? override))) override)
     (else (string-append (data-home) "/ask-ai/history.org")))))

;; ── Helpers ────────────────────────────────────────────────────────────────
(define (die msg)
  (format (current-error-port) "ask-ai: ~a~%" msg)
  (exit 1))

(define (mkdir-p dir)
  "Create DIR and any missing parents."
  (unless (or (string-null? dir) (file-exists? dir))
    (mkdir-p (dirname dir))
    (mkdir dir)))

(define (timestamp)
  (strftime "%Y-%m-%d %H:%M" (localtime (current-time))))

(define (log-exchange prompt reply)
  "Append PROMPT/REPLY to `history-file' as an Org entry; never fatal."
  (when history-file
    (false-if-exception
     (let ((dir (dirname history-file)))
       (mkdir-p dir)
       (let ((port (open-file history-file "a")))
         (format port "* ~a  ·  ~a~%" (timestamp) model)
         (format port "#+begin_quote~%~a~%#+end_quote~%~a~%~%"
                 (string-trim-both prompt) (string-trim-both reply))
         (close-port port))))))

(define (shell-quote s)
  "POSIX single-quote S so it survives /bin/sh word splitting."
  (string-append
   "'" (string-join (string-split s #\') "'\\''") "'"))

(define (read-prompt args)
  "Prompt is the joined CLI arguments, or stdin when none are given."
  (let ((joined (string-trim-both (string-join (cdr args) " "))))
    (if (string-null? joined)
        (string-trim-both (get-string-all (current-input-port)))
        joined)))

(define (curl-post url headers body)
  "POST BODY to URL with HEADERS (alist of name . value); return the response."
  (call-with-output-file body-file
    (lambda (p) (put-string p body)))
  (let* ((header-args
          (string-join
           (map (lambda (h)
                  (string-append
                   "-H " (shell-quote (string-append (car h) ": " (cdr h)))))
                headers)
           " "))
         (cmd (string-append
               "curl -sS --max-time 60 " header-args
               " --data-binary @" (shell-quote body-file)
               " " (shell-quote url)))
         (port (open-input-pipe cmd))
         (out (get-string-all port))
         (status (close-pipe port)))
    (unless (zero? status) (die "curl request failed (network or auth)"))
    out))

(define (answer-text parsed)
  "Pull the text out of a /v1/messages response, or surface an API error."
  (let ((content (assoc-ref parsed "content"))
        (err     (assoc-ref parsed "error")))
    (cond
     ((and (vector? content) (> (vector-length content) 0))
      (or (assoc-ref (vector-ref content 0) "text") ""))
     (err (string-append "API error: "
                         (or (assoc-ref err "message") "unknown")))
     (else "(no content returned)"))))

;; ── Main ───────────────────────────────────────────────────────────────────
(define (main args)
  (unless (and api-key (not (string-null? api-key)))
    (die "ANTHROPIC_API_KEY is not set"))
  (let ((prompt (read-prompt args)))
    (when (string-null? prompt) (die "empty prompt"))
    (let* ((body (scm->json-string
                  `(("model"      . ,model)
                    ("max_tokens" . ,max-tokens)
                    ("system"     . ,system-prompt)
                    ("messages"   . #((("role" . "user")
                                       ("content" . ,prompt)))))))
           (raw (curl-post "https://api.anthropic.com/v1/messages"
                           `(("content-type"     . "application/json")
                             ("x-api-key"         . ,api-key)
                             ("anthropic-version" . "2023-06-01"))
                           body))
           (reply (string-trim-both (answer-text (json-string->scm raw)))))
      (log-exchange prompt reply)
      (display reply)
      (newline))))

(main (command-line))
