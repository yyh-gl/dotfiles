;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: TypeScript / JavaScript / React (tree-sitter)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Tree-sitter grammars (typescript / tsx) are provided declaratively via Nix
;; and symlinked into ~/.emacs.d/tree-sitter/ (see nix/home/emacs.nix).

;; .ts -> typescript-ts-mode, .tsx/.jsx -> tsx-ts-mode (both built-in)
(use-package typescript-ts-mode
  :ensure nil
  :mode (("\\.ts\\'"  . typescript-ts-mode)
         ("\\.tsx\\'" . tsx-ts-mode)
         ("\\.jsx\\'" . tsx-ts-mode))
  :hook ((typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode        . eglot-ensure))
  :config
  (setq typescript-ts-mode-indent-offset 2))

;; js-mode is built-in
(add-hook 'js-mode-hook #'eglot-ensure)

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((typescript-ts-mode tsx-ts-mode js-mode)
                 . ("typescript-language-server" "--stdio"))))

(provide 'typescript)
