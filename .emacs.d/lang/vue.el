;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: Vue
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; vue-mode is unavailable on MELPA; use web-mode for .vue files
(use-package web-mode
  :ensure t
  :mode "\\.vue\\'")

(with-eval-after-load 'eglot
  ;; Pick LSP server based on file extension (vue vs jsx/tsx)
  (add-to-list 'eglot-server-programs
               `(web-mode . ,(lambda (&rest _)
                               (if (string-suffix-p ".vue" (or buffer-file-name ""))
                                   '("vue-language-server" "--stdio")
                                 '("typescript-language-server" "--stdio"))))))

(provide 'vue)
;;; lang/vue.el ends here
