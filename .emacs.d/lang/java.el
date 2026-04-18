;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: Java
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; java-mode is built-in
(add-hook 'java-mode-hook #'eglot-ensure)

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(java-mode . ("jdtls"))))

(provide 'java)
