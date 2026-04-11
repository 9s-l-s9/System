(define-module (services helix)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu packages editors)
  #:use-module (gnu services)
  #:use-module (services helix-home-services)
  #:export (helix-service))

(define helix-service
  (home-helix-service-type
   (home-helix-configuration
    (package helix)
    (config
     (list
      ;; Main editor config
      (helix-config "editor"
                   '(theme "ayu_dark")
                   '(scrolloff 5)
                   '(mouse #t)
                   '(middle-click-paste #t)
                   '(scroll-lines 3)
                   '(shell ("sh" "-c"))
                   '(line-number "relative")
                   '(cursorline #f)
                   '(cursorcolumn #f)
                   '(auto-completion #t)
                   '(auto-format #t)
                   '(idle-timeout 250)
                   '(completion-timeout 250)
                   '(preview-completion-insert #t)
                   '(completion-trigger-len 1)
                   '(completion-replace #t)
                   '(auto-info #t)
                   '(true-color #f)
                   '(undercurl #f)
                   '(rulers ())
                   '(bufferline "multiple")
                   '(color-modes #f)
                   '(text-width 80)
                   '(workspace-lsp-roots ())
                   '(default-line-ending "native")
                   '(insert-final-newline #t)
                   '(popup-border "none")
                   '(indent-heuristic "hybrid")
                   '(jump-label-alphabet "abcdefghijklmnopqrstuvwxyz")
                   '(end-of-line-diagnostics "hint"))
                   
      ;; Auto-save configuration
      (helix-config "editor.auto-save"
                   '(focus-lost #t)
                   '(after-delay.enable #t)
                   '(after-delay.timeout 600))
                   
      ;; Statusline configuration
      (helix-config "editor.statusline"
                   '(left ("mode" "spinner" "file-name" "read-only-indicator" 
                           "file-modification-indicator"))
                   '(center ())
                   '(right ("file-encoding" "file-line-ending" "diagnostics" "selections" 
                           "register" "file-type" "total-line-numbers" 
                           "position-percentage" "position"))
                   '(separator "│")
                   '(mode.normal "NORMAL")
                   '(mode.insert "INSERT")
                   '(mode.select "SELECT"))
                   
      ;; LSP configuration
      (helix-config "editor.lsp"
                   '(enable #t)
                   '(display-messages #f)
                   '(auto-signature-help #t)
                   '(display-inlay-hints #f)
                   '(display-signature-help-docs #t)
                   '(snippets #t)
                   '(goto-reference-include-declaration #t))
                   
      ;; Cursor shape configuration
      (helix-config "editor.cursor-shape"
                   '(normal "block")
                   '(insert "bar")
                   '(select "underline"))
                   
      ;; File picker configuration
      (helix-config "editor.file-picker"
                   '(hidden #f)
                   '(follow-symlinks #t)
                   '(deduplicate-links #t)
                   '(parents #t)
                   '(ignore #t)
                   '(git-ignore #t)
                   '(git-global #t)
                   '(git-exclude #t))
                   
      ;; Auto-pairs configuration - much more concise now!
      (helix-config "editor.auto-pairs"
                   '("(" ")")
                   '("{" "}")
                   '("[" "]")
                   '("\"" "\"")
                   '("`" "`")
                   '("<" ">"))
                   
      ;; Search configuration
      (helix-config "editor.search"
                   '(smart-case #t)
                   '(wrap-around #t))
                   
      ;; Whitespace rendering
      (helix-config "editor.whitespace.render"
                   '(space "all")
                   '(tab "all")
                   '(nbsp "all")
                   '(nnbsp "all")
                   '(newline "all"))
                   
      ;; Whitespace characters
      (helix-config "editor.whitespace.characters"
                   '(space "·")
                   '(nbsp "⍽")
                   '(nnbsp "␣")
                   '(tab "→")
                   '(newline "⏎")
                   '(tabpad "·"))
                   
      ;; Indent guides
      (helix-config "editor.indent-guides"
                   '(render #f)
                   '(character "│")
                   '(skip-levels 0))
                   
      ;; Gutters configuration
      (helix-config "editor.gutters"
                   '(layout ("diagnostics" "spacer" "line-numbers" "spacer" "diff")))
                   
      ;; Line numbers in gutters
      (helix-config "editor.gutters.line-numbers"
                   '(min-width 1))
                   
      ;; Soft wrap configuration
      (helix-config "editor.soft-wrap"
                   '(enable #t)
                   '(max-wrap 20)
                   '(max-indent-retain 40)
                   '(wrap-indicator "↪")
                   '(wrap-at-text-width #f))
                   
      ;; Smart tab configuration
      (helix-config "editor.smart-tab"
                   '(enable #t)
                   '(supersede-menu #f))
                   
      ;; Inline diagnostics
      (helix-config "editor.inline-diagnostics"
                   '(cursor-line "warning")
                   '(other-lines "disable")
                   '(prefix-len 1)
                   '(max-wrap 20)
                   '(max-diagnostics 10))))
                   
    ;; Language servers
    (language-servers
     (list
      (helix-language-server
       (name "guile-lsp-server")
       (command "guile-lsp-server")
       (args '("--stdio")))))
       
    ;; Language configurations
    (languages
     (list
      (helix-language
       (name "scheme")
       (config
        `((base . ((scope . "source.scheme")
                   (injection-regex . "scheme")
                   (file-types . ("ss" "scm" "skr"))
                   (shebangs . ("scheme" "guile" "chicken"))
                   (comment-token . ";")
                   (language-servers . ("guile-lsp-server"))
                   (auto-format . #t)))
          (indent . ((tab-width . 2)
                     (unit . "  ")))
          (auto-pairs . (("(" . ")")
                         ("{" . "}")
                         ("[" . "]")
                         ("\"" . "\""))))))))
                         
    ;; Grammar configurations
    (grammars
     (list
      (helix-grammar
       (name "scheme")
       (source `((git . "https://github.com/6cdh/tree-sitter-scheme")
                 (rev . "63e25a4a84142ae7ee0ee01fe3a32c985ca16745")))))))))
