;;; init.el -- My Emacs configuration
;-*-Emacs-Lisp-*-

;;; Commentary:
;;
;; I have nothing substantial to say here.
;;
;;; Code:

(setq-default buffer-file-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)
(setq locale-coding-system 'utf-8-unix)
(prefer-coding-system 'utf-8-unix)

(setq initial-scratch-message
      (concat
       ";; This buffer is for text that is not saved, and for Lisp evaluation.\n"
       ";; To create a file, visit it with C-x C-f and enter text in its buffer.\n"
       ";;\n"
       ";; __          __  _                            \n"
       ";; \\ \\        / / | |                           \n"
       ";;  \\ \\  /\\  / /__| | ___ ___  _ __ ___   ___   \n"
       ";;   \\ \\/  \\/ / _ \\ |/ __/ _ \\| '_ ` _ \\ / _ \\  \n"
       ";;    \\  /\\  /  __/ | (_| (_) | | | | | |  __/_ \n"
       ";;     \\/  \\/ \\___|_|\\___\\___/|_| |_| |_|\\___(_)\n"))

;; Leave this here, or package.el will just add it again.
(package-initialize)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; Also add all directories within "lisp"
;; I use this for packages I'm actively working on, mostly.
(let ((files (directory-files-and-attributes (expand-file-name "lisp" user-emacs-directory) t)))
  (dolist (file files)
    (let ((filename (car file))
          (dir (nth 1 file)))
      (when (and dir
                 (not (string-suffix-p "." filename)))
        (add-to-list 'load-path (car file))))))

(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))

(if (not (eq window-system 'w32))
    (add-to-list 'exec-path "/usr/local/bin"))

;; Don't litter my init file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror)

(require 'init-utils)
(require 'init-elpa)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

;; Essential settings.
(setq inhibit-splash-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(when (boundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(show-paren-mode 1)
(setq show-paren-delay 0)

(setq visual-line-fringe-indicators '(left-curly-arrow right-curly-arrow))
(setq-default left-fringe-width nil)
(setq-default indicate-empty-lines t)
(setq-default indent-tabs-mode nil)

(setq visible-bell t)
(setq vc-follow-symlinks t)
(setq large-file-warning-threshold nil)
(setq split-width-threshold nil)
(setq custom-safe-themes t)
(column-number-mode t)
(setq tab-width 4)
(setq tramp-default-method "ssh")
(setq tramp-syntax 'simplified)
(setq sentence-end-double-space nil)

;; Allow "confusing" functions
(put 'narrow-to-region 'disabled nil)
(put 'dired-find-alternate-file 'disabled nil)

(defun air--delete-trailing-whitespace-in-prog-and-org-files ()
  "Delete trailing whitespace if the buffer is in `prog-' or `org-mode'."
  (if (or (derived-mode-p 'prog-mode)
          (derived-mode-p 'org-mode))
      (delete-trailing-whitespace)))
(add-to-list 'write-file-functions 'air--delete-trailing-whitespace-in-prog-and-org-files)

(defun my-minibuffer-setup-hook ()
  "Increase GC cons threshold."
  (setq gc-cons-threshold most-positive-fixnum))

(defun my-minibuffer-exit-hook ()
  "Set GC cons threshold to its default value."
  (setq gc-cons-threshold 1000000))

(add-hook 'minibuffer-setup-hook #'my-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my-minibuffer-exit-hook)

(defvar backup-dir "~/.emacs.d/backups/")
(setq backup-directory-alist (list (cons "." backup-dir)))
(setq make-backup-files nil)

;;; File type overrides.
(add-to-list 'auto-mode-alist '("\\.restclient$" . restclient-mode))

;;; My own configurations, which are bundled in my dotfiles.
(require 'init-platform)
(require 'init-global-functions)

;; Utilities
(use-package s
  :ensure t
  :defer t)

(use-package dash
  :ensure t
  :defer t)

(use-package magit
  :ensure t
  :defer t
  :config
  (setq magit-branch-arguments nil)
  (setq magit-push-always-verify nil)
  (setq magit-last-seen-setup-instructions "1.4.0")
  (add-hook 'magit-mode-hook
            (lambda ()
              (define-key magit-mode-map (kbd ",o") 'delete-other-windows)))
  (add-hook 'git-commit-mode-hook 'evil-insert-state))

(use-package smart-mode-line
  :ensure t
  :config
  (setq sml/theme 'dark)
  (sml/setup))

(use-package wc-mode
  :ensure t
  :config
  (setq wc-modeline-format "WC[%tc/%tw]"))

;;; Required by init-maps, so it appears up here.
(use-package tiny-menu
  :ensure t
  :commands (tiny-menu-run-item)
  :config
  (setq tiny-menu-items
        '(("reverts"      ("Revert"
                           ((?r "This buffer"     revert-buffer)
                            (?o "All Org buffers" org-revert-all-org-buffers))))
          ("theme"        ("Theme"
                           ((?l "Light"      (lambda () (air-set-theme :light)))
                            (?d "Dark"       (lambda () (air-set-theme :dark))))))
          ("org-goto"     ("Goto"
                           ((?t "Tag"        air-org-display-any-tag)
                            (?i "ID"         air-org-goto-custom-id)
                            (?k "Keyword"    org-search-view)
                            (?h "Headings"   air-org-helm-headings)
                            (?s "Search"     air-org-grep))))
          ("org-agendas"  ("Org Agenda Views"
                           ((?a "All"      air-pop-to-org-agenda-default)
                            (?r "Review"   air-pop-to-org-agenda-review)
                            (?c "Calendar" calendar)
                            )))
          ("org-links"    ("Org Links"
                           ((?c "Capture"        org-store-link)
                            (?l "Insert DWIM"    air-org-insert-link-dwim)
                            (?L "Insert any"     org-insert-link)
                            (?i "Custom ID"      air-org-insert-custom-id-link)
                            (?t "Toggle display" org-toggle-link-display))))
          ("org-files"    ("Org Files"
                           ((?t "TODO"  (lambda () (air-pop-to-org-todo nil)))
                            (?n "Notes" (lambda () (interactive) (air-pop-to-org-notes nil)))
                            (?v "Vault" (lambda () (interactive) (air-pop-to-org-vault nil))))))
          ("org-captures" ("Create"
                           ((?c "Task"    (lambda () (interactive) (org-capture nil "c")))
                            (?b "Backlog" (lambda () (interactive) (org-capture nil "b")))
                            (?n "Note"    (lambda () (interactive) (org-capture nil "n")))
                            (?j "Journal" org-journal-new-entry)))))))

;;; Larger package-specific configurations.
(require 'init-fonts)
(require 'init-evil)
(require 'init-maps)
(require 'init-w3m)
(require 'init-flycheck)
(require 'init-tmux)

;; My packages (make sure they're cloned into "lisp")
(require 'fence-edit)

(require 'hugo)
(setq hugo-default-server-flags '(drafts future))
(setq hugo-create-post-bundles t)
(global-set-key (kbd "C-c h s") 'hugo-status)

(define-key hugo-mode-map (kbd "C") 'air-hugo-maybe-create-status-post)
(defun air-hugo-maybe-create-status-post ()
  "If we're in the \=status\= blog, create a new status post."
  (interactive)
  (let* ((project (car (last
                        (cl-remove-if
                         (lambda (i) (string= i ""))
                         (file-name-split (hugo--get-root)))))))
    (if (string= project "status")
        (hugo--create-content "posts" (format-time-string "%Y-%m-%d %H:%M %A"))
      (error "Status posts must be created in the status blog"))))

(define-key hugo-mode-map (kbd "T") 'air-hugo-open-shell)
(defun air-hugo-open-shell ()
  "Open a shell in another window at the root of the Hugo project."
  (interactive)
  (let ((pwd (hugo--get-root)))
    (with-temp-buffer
      (cd pwd)
      (let ((buf (eshell)))
        (switch-to-buffer (other-buffer buf))
        (switch-to-buffer-other-window buf)))))

(define-key hugo-mode-map (kbd "D") 'air-hugo-just-deploy)
(defun air-hugo-just-deploy ()
  "Deploy the current Hugo site by running a Just recipe."
  (interactive)
  (let* ((buf (get-buffer-create  "*just-deploy*"))
         (pwd (hugo--get-root))
         (map (make-sparse-keymap)))
    (define-key map (kbd "q") (lambda ()
                                (interactive)
                                (quit-window)
                                (kill-buffer "*just-deploy*")))
    (with-current-buffer buf
      (setq buffer-read-only t)
      (kill-all-local-variables)
      ;; This is the magic that makes my key binding override evil
      (setq-local overriding-local-map map)
      (cd pwd)
      (pop-to-buffer buf)
      (let ((inhibit-read-only t))
        (eshell-command "just deploy" t)
        (require 'ansi-color)
        (ansi-color-apply-on-region (point-min) (point-max)))
      (goto-char (point-max))
      (recenter -1))))

(require 'periodic-commit-minor-mode)

(use-package visual-fill-column
  :ensure t
  :defer t)

;; Org Mode
(require 'init-org)

(use-package all-the-icons
  :ensure t
  :defer t)

(use-package all-the-icons-dired
  :ensure t
  :defer t)

(use-package helm-make
  :ensure t
  :defer t
  :config
  (global-set-key (kbd "C-c m") 'helm-make-projectile))

(use-package dired
  :defer t
  :config
  (require 'dired-x)
  (setq dired-omit-files "^\\.?#\\|^\\.[^.].*")

  (defun air-dired-buffer-dir-or-home ()
    "Open dired to the current buffer's dir, or $HOME."
    (interactive)
    (let ((cwd (or (file-name-directory (or (buffer-file-name) ""))
                   (expand-file-name "~"))))
      (dired cwd)))

  (add-hook 'dired-mode-hook (lambda ()
                               (dired-omit-mode t)
                               (all-the-icons-dired-mode t)))
  (define-key dired-mode-map (kbd "RET")     'dired-find-alternate-file)
  (define-key dired-mode-map (kbd "^")       (lambda () (interactive) (find-alternate-file "..")))
  (define-key dired-mode-map (kbd "C-.")     'dired-omit-mode)
  (define-key dired-mode-map (kbd "c")       'find-file)
  (define-key dired-mode-map (kbd "/")       'counsel-grep-or-swiper)
  (define-key dired-mode-map (kbd "?")       'evil-search-backward)
  (define-key dired-mode-map (kbd "C-c C-c") 'dired-toggle-read-only))

(eval-after-load 'wdired
  (add-hook 'wdired-mode-hook 'evil-normal-state))

(use-package elpy
  :ensure t
  :mode "\\.py\\'"
  :config
  (elpy-enable))

(use-package go-mode
  :ensure t
  :mode "\\.go\\'"
  :config
  (add-hook 'go-mode-hook (lambda ()
                            (if (not (string-match "go" compile-command))
                                (set (make-local-variable 'compile-command)
                                     "go build -v && go test -v && go vet"))
                            (setq compilation-read-command nil)
                            (add-hook 'before-save-hook 'gofmt-before-save nil t)
                            (define-key go-mode-map (kbd "C-c C-C") 'compile))))

(use-package rjsx-mode
  :ensure t
  :mode "\\.js\\'"
  :config
  (defun rjsx-mode-config ()
    "Configure RJSX Mode"
    (define-key rjsx-mode-map (kbd "C-j") 'rjsx-delete-creates-full-tag))
  (add-hook 'rjsx-mode-hook 'rjsx-mode-config))

(use-package groovy-mode
  :ensure t
  :mode "\\.groovy\\'"
  :config
  (c-set-offset 'label 4))

(use-package rainbow-mode
  :ensure t
  :commands rainbow-mode)

(use-package css-mode
  :ensure t
  :mode "\\.css\\'"
  :config
  (add-hook 'css-mode-hook (lambda ()
                             (rainbow-mode))))

(use-package wgrep
  :ensure t
  :defer t
  :config
  (setq wgrep-auto-save-buffer t)
  (defadvice wgrep-change-to-wgrep-mode (after wgrep-set-normal-state)
    (if (fboundp 'evil-normal-state)
        (evil-normal-state)))
  (ad-activate 'wgrep-change-to-wgrep-mode)

  (defadvice wgrep-finish-edit (after wgrep-set-motion-state)
    (if (fboundp 'evil-motion-state)
        (evil-motion-state)))
  (ad-activate 'wgrep-finish-edit))

(use-package wgrep-ag
  :ensure t
  :commands (wgrep-ag-setup))

(use-package ag
  :ensure t
  :commands (ag ag-project)
  :config
  (add-hook 'ag-mode-hook
            (lambda ()
              (wgrep-ag-setup)
              (define-key ag-mode-map (kbd "n") 'evil-search-next)
              (define-key ag-mode-map (kbd "N") 'evil-search-previous)))
  (setq ag-executable "/usr/local/bin/ag")
  (setq ag-highlight-search t)
  (setq ag-reuse-buffers t)
  (setq ag-reuse-window t))

(use-package deadgrep
  :ensure t)

(use-package js2-mode
  :ensure t
  :defer t
  :config
  (setq js2-strict-missing-semi-warning nil)
  (setq js2-missing-semi-one-line-override t))

(use-package exec-path-from-shell
  :ensure t
  :defer t
  :config
  (when (memq window-system '(mac ns))
    (setq exec-path-from-shell-arguments nil)
    (exec-path-from-shell-initialize)))

(use-package helm
  :ensure t
  :diminish helm-mode
  :commands helm-mode
  :config
  (helm-mode 1)
  (setq helm-buffers-fuzzy-matching t)
  (setq helm-autoresize-mode t)
  (setq helm-buffer-max-length 40)
  (define-key helm-map (kbd "S-SPC")          'helm-toggle-visible-mark)
  (define-key helm-find-files-map (kbd "C-k") 'helm-find-files-up-one-level)
  (define-key helm-read-file-map (kbd "C-k")  'helm-find-files-up-one-level))

(use-package helm-org
  :ensure t
  :commands helm-org-agenda-files-headings)

(use-package company
  :ensure t
  :defer 2
  :config
  (defun org-keyword-backend (command &optional arg &rest ignored)
    "Company backend for org keywords.

COMMAND, ARG, IGNORED are the arguments required by the variable
`company-backends', which see."
    (interactive (list 'interactive))
    (cl-case command
      (interactive (company-begin-backend 'org-keyword-backend))
      (prefix (and (eq major-mode 'org-mode)
                   (let ((p (company-grab-line "^#\\+\\(\\w*\\)" 1)))
                     (if p (cons p t)))))
      (candidates (mapcar #'upcase
                          (cl-remove-if-not
                           (lambda (c) (string-prefix-p arg c))
                           (pcomplete-completions))))
      (ignore-case t)
      (duplicates t)))
  (add-to-list 'company-backends 'org-keyword-backend)

  (setq company-idle-delay 0.4)
  (setq company-selection-wrap-around t)
  (define-key company-active-map (kbd "ESC") 'company-abort)
  (define-key company-active-map [tab] 'company-complete-common-or-cycle)
  (define-key company-active-map (kbd "C-n") 'company-select-next)
  (define-key company-active-map (kbd "C-p") 'company-select-previous)

  (global-company-mode))

(use-package counsel
  :ensure t
  :defer t)

(use-package swiper
  :ensure t
  :commands swiper
  :bind ("C-s" . counsel-grep-or-swiper)
  :config
  (require 'counsel)
  (setq counsel-grep-base-command "grep -niE \"%s\" %s")
  (setq ivy-height 20))

(use-package dictionary
  :ensure t
  :defer t)

(use-package emmet-mode
  :ensure t
  :commands emmet-mode
  :config
  (add-hook 'emmet-mode-hook
            (lambda ()
              (evil-define-key 'insert emmet-mode-keymap (kbd "C-S-l") 'emmet-next-edit-point)
              (evil-define-key 'insert emmet-mode-keymap (kbd "C-S-h") 'emmet-prev-edit-point))))

(use-package flycheck
  :ensure t
  :commands flycheck-mode)

(use-package helm-projectile
  :ensure t
  :commands (helm-projectile helm-projectile-switch-project))

(use-package markdown-mode
  :ensure t
  :mode "\\.md\\'"
  :config
  (setq markdown-command "pandoc --from markdown_github-hard_line_breaks --to html")
  (setq markdown-asymmetric-header t)
  (define-key markdown-mode-map (kbd "<C-return>") 'markdown-insert-list-item)
  (define-key markdown-mode-map (kbd "C-c '")      'fence-edit-code-at-point)

  (defun air--in-markdown-link-p ()
    "Returns non-nil if point is within the text of a markdown link."
    ;; This got way more complicated than I hoped.
    (let ((pt (point))
          (link-start-behind
           (save-excursion
             (re-search-backward "^\\|[^]]\\[" (line-beginning-position) t)))
          (link-start-ahead
           (save-excursion
             (re-search-forward "[^]]\\[" (line-end-position) t)))
          (link-end-behind
           (save-excursion
             (re-search-backward  "\\][[(]" (line-beginning-position) t)))
          (link-end-ahead
           (save-excursion
             (re-search-forward  "\\][[(]" (line-end-position) t))))
      (and
       (eq major-mode 'markdown-mode)
       link-start-behind
       link-end-ahead
       (or (not link-end-behind)
           (< link-end-behind link-start-behind))
       (or (not link-start-ahead)
           (> link-start-ahead link-end-ahead)))))

  (defun air--before-markdown-insert-list-item (&optional arg)
    "Insert a newline before a markdown list item

Okay so it's two newlines, but that's because markdown list items are
inserted on the current line if the current line is blank, and the
goal is to have a blank line between list items."
    (if (markdown-list-item-at-point-p)
        (insert "\n\n")))

  (advice-add 'markdown-insert-list-item
              :before
              'air--before-markdown-insert-list-item)

  (add-hook 'markdown-mode-hook (lambda ()
                                  (evil-define-key 'normal markdown-mode-map (kbd "C-c W") 'air-browse-current-file-location)
                                  (visual-line-mode t)
                                  (set-fill-column 80)
                                  (yas-minor-mode-on)
                                  (hugo-minor-mode t)
                                  (turn-on-auto-fill)
                                  (flyspell-mode)
                                  (wc-mode t)
                                  ;; Don't wrap Liquid tags
                                  (setq auto-fill-inhibit-regexp (rx "{" (? "{") (1+ (or "%" "<" " ")) (1+ letter)))
                                  ;; Don't break inside links
                                  (add-to-list 'fill-nobreak-predicate 'air--in-markdown-link-p)
                                  )))

(defun air-set-theme (mode)
  "Set a theme for MODE `:dark' or `:light'."
  (setq custom--inhibit-theme-enable nil)
  (let ((face-height (face-attribute 'default :height)))
    (while (> (length custom-enabled-themes) 0)
      (disable-theme (car custom-enabled-themes)))
    (cond ((eq mode :dark)
           (if (> (length custom-enabled-themes) 0)
               (disable-theme (car custom-enabled-themes)))
           (load-theme 'solarized-wombat-dark t)
           (custom-theme-set-faces
            'solarized-wombat-dark
            '(markdown-comment-face ((t (:foreground "#757575"))))
            '(markdown-inline-code-face ((t (:foreground "#959595"))))
            '(markdown-pre-face ((t (:foreground "#959595"))))
            '(markdown-url-face ((t (:foreground "#959595"))))
            '(markdown-markup-face ((t (:foreground "#959595"))))
            '(markdown-metadata-key-face ((t (:foreground "#757575"))))
            '(org-agenda-structure ((t (:background "#353535")))))
           (set-background-color "#222222"))
          ((eq mode :light)
           (message "Enabling light theme.")
           (custom-theme-set-faces
            'solarized-light-high-contrast
            '(markdown-comment-face ((t (:foreground "#98a6a6" :strike-through nil)))))
           (load-theme 'solarized-light-high-contrast t)))
    (set-face-attribute 'default nil :height face-height)))

(use-package solarized-theme
  :ensure t
  :config
  (setq solarized-use-variable-pitch nil)
  (setq solarized-scale-org-headlines nil)
  (air-set-theme :dark))

(use-package web-mode
  :ensure t
  :mode "\\(?:\\(?:\\.\\(?:html\\|twig\\)\\)\\)\\'"
  :config
  (setq web-mode-attr-indent-offset 2
        web-mode-code-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-indent-style 2
        web-mode-markup-indent-offset 2
        web-mode-sql-indent-offset 2)

  (setq web-mode-ac-sources-alist
        '(("php" . (ac-source-php-extras
                    ac-source-yasnippet
                    ac-source-gtags
                    ac-source-abbrev
                    ac-source-dictionary
                    ac-source-words-in-same-mode-buffers))
          ("css" . (ac-source-css-property
                    ac-source-abbrev
                    ac-source-dictionary
                    ac-source-words-in-same-mode-buffers))))

  (add-hook 'web-mode-hook
            (lambda ()
              (setq web-mode-style-padding 2)
              (yas-minor-mode t)
              (emmet-mode)
              (flycheck-add-mode 'html-tidy 'web-mode)
              (flycheck-mode)))

  (add-hook 'web-mode-before-auto-complete-hooks
            (lambda ()
               (let ((web-mode-cur-language (web-mode-language-at-pos)))
                 (if (string= web-mode-cur-language "php")
                     (yas-activate-extra-mode 'php-mode)
                   (yas-deactivate-extra-mode 'php-mode))
                 (if (string= web-mode-cur-language "css")
                     (setq emmet-use-css-transform t)
                   (setq emmet-use-css-transform nil))))))

(use-package yaml-mode
  :ensure t
  ;; .yaml or .yml
  :mode "\\(?:\\(?:\\.y\\(?:a?ml\\)\\)\\)\\'")

(use-package yasnippet
  :ensure t
  :defer t
  :config
  (setq tab-always-indent 'complete)
  (define-key yas-minor-mode-map (kbd "<escape>") 'yas-exit-snippet)
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :ensure t
  :defer t)

(use-package which-key
  :ensure t
  :diminish ""
  :config
  (which-key-mode))

(use-package projectile
  :ensure t
  :defer t
  :config
  (projectile-mode)
  (add-to-list 'projectile-globally-ignored-directories "*node_modules")
  (setq projectile-enable-caching t)
  (setq projectile-mode-line
        '(:eval
          (format " Proj[%s]"
                  (projectile-project-name)))))

(use-package highlight-symbol
  :ensure t
  :defer t
  :diminish ""
  :config
  (setq-default highlight-symbol-idle-delay 1.5))

(use-package mmm-mode
  :ensure t
  :defer t
  :config
  (setq mmm-global-mode 'maybe)
  (mmm-add-classes
   '((markdown-cl
      :submode emacs-lisp-mode
      :face mmm-declaration-submode-face
      :front "^~~~cl[\n\r]+"
      :back "^~~~$")
     (markdown-php
      :submode php-mode
      :face mmm-declaration-submode-face
      :front "^```php[\n\r]+"
      :back "^```$")))
  (mmm-add-mode-ext-class 'markdown-mode nil 'markdown-cl)
  (mmm-add-mode-ext-class 'markdown-mode nil 'markdown-php))

;;; Helpers for GNUPG, which I use for encrypting/decrypting secrets.
(require 'epa-file)
(setq-default epa-file-cache-passphrase-for-symmetric-encryption t)

;;; Flycheck mode:
(add-hook 'flycheck-mode-hook
          (lambda ()
            (evil-define-key 'normal flycheck-mode-map (kbd "]e") 'flycheck-next-error)
            (evil-define-key 'normal flycheck-mode-map (kbd "[e") 'flycheck-previous-error)))

;;; Lisp interaction mode & Emacs Lisp mode:
(add-hook 'lisp-interaction-mode-hook
          (lambda ()
            (define-key lisp-interaction-mode-map (kbd "<C-return>") 'eval-last-sexp)))

;;; All programming modes
(defun air--set-up-prog-mode ()
  "Configure global `prog-mode'."
  (setq-local comment-auto-fill-only-comments t)
  (electric-pair-local-mode))
(add-hook 'prog-mode-hook 'air--set-up-prog-mode)

;;; If `display-line-numbers-mode' is available (only in Emacs 26),
;;; use it! Otherwise, install and run nlinum-relative.
(if (functionp 'display-line-numbers-mode)
    (and (add-hook 'display-line-numbers-mode-hook
                   (lambda () (setq display-line-numbers-type 'relative)))
         (add-hook 'prog-mode-hook #'display-line-numbers-mode))
  (use-package nlinum-relative
    :ensure t
    :config
    (nlinum-relative-setup-evil)
    (setq nlinum-relative-redisplay-delay 0)
    (add-hook 'prog-mode-hook #'nlinum-relative-mode)))

;;; Python mode:
(use-package virtualenvwrapper
  :ensure t
  :defer t
  :config
  (venv-initialize-interactive-shells)
  (venv-initialize-eshell))

(defun air-python-setup ()
  "Configure Python environment."
  (let* ((root (air--get-vc-root))
         (venv-name (car (last (remove "" (split-string root "/")))))
         (venv-path (expand-file-name venv-name venv-location)))
    (if (and venv-name
             venv-path
             (file-directory-p venv-path))
        (venv-workon venv-name))))

(add-hook 'python-mode-hook
          (lambda ()
            ;; I'm rudely redefining this function to do a comparison of `point'
            ;; to the end marker of the `comint-last-prompt' because the original
            ;; method of using `looking-back' to match the prompt was never
            ;; matching, which hangs the shell startup forever.
            (defun python-shell-accept-process-output (process &optional timeout regexp)
              "Redefined to actually work."
              (let ((regexp (or regexp comint-prompt-regexp)))
                (catch 'found
                  (while t
                    (when (not (accept-process-output process timeout))
                      (throw 'found nil))
                    (when (= (point) (cdr (python-util-comint-last-prompt)))
                      (throw 'found t))))))

            ;; Additional settings follow.
            (add-to-list 'write-file-functions 'delete-trailing-whitespace)
            (air-python-setup)))

;;; The Emacs Shell
(defun company-eshell-history (command &optional arg &rest ignored)
  "Complete from shell history when starting a new line.

Provide COMMAND and ARG in keeping with the Company Mode backend spec.
The IGNORED argument is... Ignored."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-eshell-history))
    (prefix (and (eq major-mode 'eshell-mode)
                 (let ((word (company-grab-word)))
                   (save-excursion
                     (eshell-bol)
                     (and (looking-at-p (s-concat word "$")) word)))))
    (candidates (remove-duplicates
                 (->> (ring-elements eshell-history-ring)
                      (remove-if-not (lambda (item) (s-prefix-p arg item)))
                      (mapcar 's-trim))
                 :test 'string=))
    (sorted t)))

(defadvice term-sentinel (around my-advice-term-sentinel (proc msg))
  "Kill term buffer when term is ended."
  (if (memq (process-status proc) '(signal exit))
      (let ((buffer (process-buffer proc)))
        ad-do-it
        (kill-buffer buffer))
    ad-do-it))
(ad-activate 'term-sentinel)

(defun air--eshell-clear ()
  "Clear an eshell buffer and re-display the prompt."
  (interactive)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (eshell-send-input)))

(defun air--eshell-mode-hook ()
  "Eshell mode settings."
  (define-key eshell-mode-map (kbd "C-u") 'eshell-kill-input)
  (define-key eshell-mode-map (kbd "C-l") 'air--eshell-clear)
  (define-key eshell-mode-map (kbd "C-d") (lambda () (interactive)
                                            (kill-this-buffer)
                                            (if (not (one-window-p))
                                                (delete-window))))
  (set (make-local-variable 'pcomplete-ignore-case) t))

(add-hook 'eshell-mode-hook 'air--eshell-mode-hook)

;;; Emacs Lisp mode:
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (yas-minor-mode t)
            (eldoc-mode)
            (highlight-symbol-mode)
            (define-key emacs-lisp-mode-map (kbd "<C-return>") 'eval-last-sexp)))

;;; SH mode:
(add-hook 'sh-mode-hook (lambda ()
                          (setq sh-basic-offset 2)
                          (setq sh-indentation 2)))

;;; Javascript mode:
(add-hook 'javascript-mode-hook (lambda ()
                                  (set-fill-column 120)
                                  (turn-on-auto-fill)
                                  (setq js-indent-level 2)))

;;; HTML mode:
(add-hook 'html-mode-hook (lambda ()
                            (setq sgml-basic-offset 2)
                            (setq indent-tabs-mode nil)))

(use-package xclip
  :ensure t
  :config
  (xclip-mode 1))

(use-package server
  :init
  (progn
    (when (equal window-system 'w32)
      ;; Set EMACS_SERVER_FILE to `server-auth-dir'\`server-name'
      ;; e.g. c:\Users\Aaron\emacs.d\server\server
      (setq server-use-tcp t)))
  :config
  (or (eq (server-running-p) t)
      (server-start)))

(use-package keychain-environment
  :ensure t
  :config (keychain-refresh-environment))

(provide 'init)
;;; init.el ends here
