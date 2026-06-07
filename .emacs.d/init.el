;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Basic Features
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq inhibit-startup-screen t)
(setq confirm-kill-processes nil)
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq require-final-newline t)
(delete-selection-mode 1)
(global-display-line-numbers-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Packages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(unless package--initialized
  (package-initialize))

;; Package Management
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ▼ Related Config Imports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-list 'load-path (expand-file-name "lang" user-emacs-directory))
(require 'go)
(require 'typescript)
(require 'kotlin)
(require 'java)
(require 'vue)
(require 'json2)
(require 'yaml)
(require 'nix)

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
  :defer t
  :bind ("C-x f" . projectile-find-file)
  :config (projectile-mode +1))

;; Theme
(use-package ayu-theme
  :ensure t
  :config (load-theme 'ayu-dark t))

;; Extend Selection
(use-package expand-region
  :ensure t
  :bind ("C-M-w" . er/expand-region))

;; File Tree
(use-package neotree
  :ensure t
  :bind ("C-\\" . neotree-toggle))

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
(defvar my--switch-to-grep-buffer nil)
(add-hook 'projectile-grep-finished-hook
          (lambda ()
            (when my--switch-to-grep-buffer
              (setq my--switch-to-grep-buffer nil)
              (let ((buf (cl-find-if
                          (lambda (b) (string-match-p "\\*grep" (buffer-name b)))
                          (buffer-list))))
                (when buf (pop-to-buffer buf))))))
(global-set-key (kbd "C-S-f")
                (lambda ()
                  (interactive)
                  (setq my--switch-to-grep-buffer t)
                  (call-interactively #'projectile-grep)))
(unless (display-graphic-p)
  (define-key key-translation-map "\e[102;6u" (kbd "C-S-f"))
  (define-key key-translation-map "\e[70;6u"  (kbd "C-S-f"))
  (when (eq system-type 'darwin)
    (setq interprogram-paste-function
          (lambda () (shell-command-to-string "pbpaste")))
    (setq interprogram-cut-function
          (lambda (text &optional _push)
            (with-temp-buffer
              (insert text)
              (call-process-region (point-min) (point-max) "pbcopy"))))))
(with-eval-after-load 'grep
  (define-key grep-mode-map (kbd "C-g") #'quit-window))
(with-eval-after-load 'compile
  (define-key compilation-button-map (kbd "RET")
    (lambda ()
      (interactive)
      (let ((buf (when (derived-mode-p 'grep-mode) (current-buffer))))
        (compile-goto-error)
        (when buf
          (let ((win (get-buffer-window buf))
                (kill-buffer-query-functions nil))
            (when win
              (quit-window t win))))))))
(with-eval-after-load 'xref
  (define-key xref--xref-buffer-mode-map (kbd "C-g") #'quit-window))
(setq xref-prompt-for-identifier
      '(not xref-find-definitions
            xref-find-definitions-other-window
            xref-find-definitions-other-frame
            xref-find-references))
(keyboard-translate ?\C-h ?\C-?)
(global-set-key (kbd "M-g")   #'goto-line)
(global-set-key (kbd "C-v")
                (lambda ()
                  (interactive)
                  (condition-case nil
                      (scroll-up-command)
                    (end-of-buffer (goto-char (point-max))))))
(global-set-key (kbd "M-v")
                (lambda ()
                  (interactive)
                  (condition-case nil
                      (scroll-down-command)
                    (beginning-of-buffer (goto-char (point-min))))))
;; Surround active region with the typed character, otherwise self-insert
(defun my-surround-or-self-insert (n)
  (interactive "p")
  (if (use-region-p)
      (let ((char (char-to-string last-command-event))
            (beg (region-beginning))
            (end (region-end)))
        (goto-char end)
        (insert char)
        (goto-char beg)
        (insert char)
        (set-mark (1+ beg))
        (goto-char (1+ end)))
    (self-insert-command n)))
(global-set-key (kbd "\"") #'my-surround-or-self-insert)
(global-set-key (kbd "'")  #'my-surround-or-self-insert)

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
