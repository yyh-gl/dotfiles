;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: Go
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package go-ts-mode
  :ensure nil
  :hook ((go-ts-mode . eglot-ensure)
         (go-ts-mode . yas-minor-mode)
         (before-save . (lambda ()
                          (when (derived-mode-p 'go-ts-mode)
                            (eglot-format-buffer)))))
  :config
  (setq go-ts-mode-indent-offset 4))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(go-ts-mode . ("gopls"))))

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
  :after go-ts-mode)

(use-package yasnippet
  :ensure t
  :defer t)

(use-package yasnippet-snippets
  :ensure t
  :defer t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(with-eval-after-load 'go-ts-mode
  (define-key go-ts-mode-map (kbd "C-c t f")
    (lambda () (interactive) (compile "go test .")))
  (define-key go-ts-mode-map (kbd "C-c t t")
    (lambda () (interactive)
      (compile (format "go test -run %s ." (thing-at-point 'symbol)))))
  (define-key go-ts-mode-map (kbd "C-c t p")
    (lambda () (interactive) (compile "go test ./...")))
  (define-key go-ts-mode-map (kbd "C-c t b")
    (lambda () (interactive) (compile "go run ."))))

(provide 'go)
