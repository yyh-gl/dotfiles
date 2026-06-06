;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Language Config: Nix
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package nix-mode
  :ensure t
  :mode ("\\.nix\\'" . nix-mode)
  :hook (nix-mode . (lambda () (setq-local indent-tabs-mode nil))))

(provide 'nix)
