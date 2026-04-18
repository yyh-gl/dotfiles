;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: Go
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package go-mode
  :ensure t
  :hook ((go-mode . eglot-ensure)
         (go-mode . yas-minor-mode)
         (before-save . gofmt-before-save))
  :config
  (setq gofmt-command "goimports"))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(go-mode . ("gopls"))))

(setq-default eglot-workspace-configuration
  '((:gopls . (:usePlaceholders t
               :staticcheck t
               :gofumpt t
               :analyses (:unusedparams t
                          :shadow t)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Packages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package dape
  :ensure t
  :after go-mode)

(use-package yasnippet
  :ensure t
  :config (yas-global-mode 1))

(use-package yasnippet-snippets
  :ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(with-eval-after-load 'go-mode
  (define-key go-mode-map (kbd "C-c t f")
    (lambda () (interactive) (compile "go test .")))
  (define-key go-mode-map (kbd "C-c t t")
    (lambda () (interactive)
      (compile (format "go test -run %s ." (thing-at-point 'symbol)))))
  (define-key go-mode-map (kbd "C-c t p")
    (lambda () (interactive) (compile "go test ./...")))
  (define-key go-mode-map (kbd "C-c t b")
    (lambda () (interactive) (compile "go run ."))))

(provide 'go)
