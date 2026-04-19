;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Basic Features
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq inhibit-startup-screen t)
(delete-selection-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Related Config Imports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-list 'load-path (expand-file-name "lang" user-emacs-directory))
(require 'go)
(require 'typescript)
(require 'kotlin)
(require 'java)
(require 'vue)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Packages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; Package Management
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

;; Auto Complete
(use-package company
  :ensure t
  :hook (after-init . global-company-mode))

;; Git
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;; Project Management
(use-package projectile
  :ensure t
  :config (projectile-mode +1))

;; Theme
(use-package ayu-theme
  :ensure t
  :config (load-theme 'ayu-dark t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Key Bindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global-set-key (kbd "C-u")
                (lambda ()
                  (interactive)
                  (kill-region (line-beginning-position) (point))))
(global-set-key (kbd "C-'")   #'xref-find-definitions)
(global-set-key (kbd "C-;")   #'xref-find-references)
(global-set-key (kbd "C-M-;") #'eglot-find-implementation)
(global-set-key (kbd "C-S-f")
                (lambda ()
                  (interactive)
                  (call-interactively #'projectile-grep)
                  (pop-to-buffer "*grep*")))
(unless (display-graphic-p)
  (define-key key-translation-map "\e[102;6u" (kbd "C-S-f"))
  (define-key key-translation-map "\e[70;6u"  (kbd "C-S-f")))
(with-eval-after-load 'grep
  (define-key grep-mode-map (kbd "C-g") #'quit-window))
(with-eval-after-load 'xref
  (define-key xref--xref-buffer-mode-map (kbd "C-g") #'quit-window))
(setq xref-prompt-for-identifier
      '(not xref-find-definitions
            xref-find-definitions-other-window
            xref-find-definitions-other-frame
            xref-find-references))
(keyboard-translate ?\C-h ?\C-?)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Hooks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(add-hook 'xref-after-jump-hook
          (lambda ()
            (let ((buf (get-buffer "*xref*")))
              (when buf (delete-windows-on buf)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Auto Generated Configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
