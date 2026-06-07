;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: Vue
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; vue-mode is unavailable on MELPA; use web-mode for .vue files.
;; web-mode is used only for .vue here (tsx/jsx live in the tree-sitter modes).
(use-package web-mode
  :ensure t
  :mode "\\.vue\\'"
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset    2
        web-mode-code-indent-offset   2))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(web-mode . ("vue-language-server" "--stdio"))))

(provide 'vue)
;;; lang/vue.el ends here
