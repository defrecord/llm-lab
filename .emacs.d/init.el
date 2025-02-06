;;; init.el --- LLM Lab Emacs Configuration

;;; Commentary:
;; This file contains the Emacs configuration for the LLM Lab project.
;; It sets up package management, project tools, and language-specific configurations.

;;; Code:

;; Early init: TLS/certificate settings
(require 'gnutls)

;; Add MITM proxy cert to trusted certificates
(let ((mitm-cert "/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"))
  (when (file-exists-p mitm-cert)
    (setq gnutls-trustfiles (list mitm-cert))))

(require 'package)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t)


;;; Project Management
(use-package projectile
  :config
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  (add-to-list 'projectile-globally-ignored-directories ".venv"))

;;; Directory Management
(use-package dired-sidebar
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :config
  (setq dired-sidebar-theme 'ascii))

;;; Org Mode Configuration
(use-package org
  :config
  (setq org-confirm-babel-evaluate nil)  ; Don't prompt for code execution
  (setq org-src-fontify-natively t)      ; Syntax highlighting in code blocks
  (setq org-src-tab-acts-natively t)     ; Tab behaves as in native mode

  ;; Active Babel languages
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)
     (python . t)
     (mermaid . t)
     (scheme . t)
     (sqlite . t)
     (emacs-lisp . t)))

  ;; Tangle settings
  (setq org-babel-default-header-args
        '((:mkdirp . "yes")              ; Create dirs if needed
          (:tangle . "yes")              ; Don't tangle by default
          (:exports . "both")            ; Export code and results
          (:results . "output")))        ; Default to output results

  (setq org-confirm-babel-evaluate nil)
  (setq make-backup-files nil)
  (setq org-src-preserve-indentation t)

  ;; Key bindings
  (global-set-key (kbd "C-c l") 'org-store-link)
  (global-set-key (kbd "C-c a") 'org-agenda)
  (global-set-key (kbd "C-c c") 'org-capture))

;;; Shell Script Mode
(use-package sh-script
  :config
  (setq sh-basic-offset 2)
  (setq sh-indentation 2)

  ;; Auto-mode for shell scripts
  (add-to-list 'auto-mode-alist '("\\.sh\\'" . sh-mode)))

;;; YAML Mode for configs
(use-package yaml-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode)))

;;; Markdown Mode
(use-package markdown-mode
  :commands (markdown-mode gfm-mode)
  :mode (("\\.md\\'" . markdown-mode))
  :init (setq markdown-command "multimarkdown"))


;; (use-package ob-mermaid :vc (:host github :repo "jwalsh/ob-mermaid"))

(use-package ob-mermaid
  :ensure t
  :after org)

;; (use-package org-contrib
;;   :ensure t
;;              :after org)

;; (use-package ox-mermaid
;;   :ensure t
;;              :after org)

(add-to-list 'org-babel-default-header-args:mermaid '(:results . "file"))
(add-to-list 'org-babel-default-header-args:mermaid '(:file . t))

(setq org-babel-directory (expand-file-name "data"))

(unless (file-exists-p org-babel-directory)
  (make-directory org-babel-directory :parents))

;;; Code Completion
(use-package company
  :config
  (global-company-mode)
  (setq company-idle-delay 0.1))

;;; Git Integration
(use-package magit
  :bind ("C-x g" . magit-status))

;;; Project-specific settings
(defun llm-lab-setup ()
  "Setup for LLM Lab project."
  (interactive)
  ;; Project root detection
  (when (projectile-project-p)
    (let ((project-root (projectile-project-root)))
      ;; Set up paths
      (setq default-directory project-root)

      ;; Configure org-mode for the project
      (setq org-directory (expand-file-name "docs" project-root))
      (setq org-default-notes-file (expand-file-name "notes.org" org-directory))

      ;; Project-specific key bindings
      (local-set-key (kbd "C-c t") 'org-babel-tangle)

      ;; Configure org-capture templates for LLM Lab
      (setq org-capture-templates
            `(("t" "Task" entry (file+headline org-default-notes-file "Tasks")
               "* TODO %?\n  %i\n  %a")
              ("p" "Prompt" entry (file+headline ,(expand-file-name "prompts.org" org-directory) "Prompts")
               "* %?\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %i")
              ("r" "Result" entry (file+headline ,(expand-file-name "results.org" org-directory) "Results")
               "* %?\n  :PROPERTIES:\n  :MODEL: \n  :PROMPT: \n  :CREATED: %U\n  :END:\n\n  %i")
              ("n" "Note" entry (file+headline org-default-notes-file "Notes")
               "* %?\n  %i\n  %a")))

      ;; Set up projectile ignores
      (add-to-list 'projectile-globally-ignored-directories ".venv")
      (add-to-list 'projectile-globally-ignored-directories "data"))))

;; Auto-activate setup for LLM Lab
(add-hook 'after-init-hook
          (lambda ()
            (when (string-match-p "llm-lab" default-directory)
              (llm-lab-setup))))

;;; Custom functions for LLM Lab
(defun llm-lab-tangle-all ()
  "Tangle all org files in the project."
  (interactive)
  (let ((org-files (directory-files-recursively (projectile-project-root) "\\.org$")))
    (dolist (file org-files)
      (with-current-buffer (find-file-noselect file)
        (org-babel-tangle)))))

(defun llm-lab-run-tests ()
  "Run project tests."
  (interactive)
  (compile "make test"))

;;; Global key bindings
(global-set-key (kbd "C-c C-t") 'llm-lab-tangle-all)
(global-set-key (kbd "C-c C-r") 'llm-lab-run-tests)

;;; File associations for LLM Lab
(add-to-list 'auto-mode-alist '("\\.prompts\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.templates\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("examples\\.org\\'" . org-mode))

(provide 'init)
;;; init.el ends here
