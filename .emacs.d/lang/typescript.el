;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: TypeScript / JavaScript / React
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; typescript-modeがflyspell-generic-progmode-verifyを参照するため先にロード
(require 'flyspell nil t)

(use-package typescript-mode
  :ensure t
  :mode "\\.ts\\'"
  :hook (typescript-mode . eglot-ensure))

;; JSX / TSX (React)
(use-package web-mode
  :ensure t
  :mode ("\\.jsx\\'" "\\.tsx\\'")
  :hook (web-mode . eglot-ensure)
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset    2
        web-mode-code-indent-offset   2))

;; js-mode is built-in
(add-hook 'js-mode-hook #'eglot-ensure)

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(typescript-mode . ("typescript-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(js-mode . ("typescript-language-server" "--stdio"))))

(provide 'typescript)
