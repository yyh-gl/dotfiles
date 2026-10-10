;;; -*- lexical-binding: t; -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: Kotlin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package kotlin-mode
  :ensure t
  ;; kotlin-language-serverを入れていない環境ではeglotを起動しない
  :hook (kotlin-mode . (lambda () (when (executable-find "kotlin-language-server") (eglot-ensure)))))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(kotlin-mode . ("kotlin-language-server"))))
