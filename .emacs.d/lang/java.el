;;; -*- lexical-binding: t; -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: Java
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; java-mode is built-in
;; jdtlsを入れていない環境ではeglotを起動しない
(add-hook 'java-mode-hook
          (lambda () (when (executable-find "jdtls") (eglot-ensure))))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(java-mode . ("jdtls"))))
