;; Enable Tree-sitter in all buffers that support it
(global-tree-sitter-mode)

;; Automatically enable Tree-sitter based syntax highlighting
(add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)

(provide 'treesitter-conf)
