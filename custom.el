(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default bold shadow italic underline bold bold-italic bold])
 '(company-gtags-modes '(jde-mode))
 '(css-indent-offset 2)
 '(custom-safe-themes
   '("91ce1e1533921a31778b95d1626371499e42d46833d703e25a07dcb8c283f4af" . t))
 '(fci-rule-color "#d6d6d6")
 '(flycheck-color-mode-line-face-to-color 'mode-line-buffer-id)
 '(flycheck-python-flake8-executable "flake8")
 '(js-indent-level 2)
 '(magit-commit-arguments nil)
 '(markdown-preview-custom-template "/Users/abieber/.emacs.d/markdown-preview-template.html")
 '(org-hide-emphasis-markers t)
 '(package-selected-packages
   '(wc-mode just-mode csv-mode evil-terminal-cursor-changer org-journal xclip undo-fu evil-org csv keychain-environment db ripgrep ahk-mode simple-httpd atomic-chrome ox-hugo ssh-agency dired gnu-elpa-keyring-update orgalist htmlize olivetti apples-mode applescript-mode magithub jade-mode yasnippet-snippets esh-autosuggest gruvbox-theme php-extras wgrep s tiny-menu writeroom-mode feature-mode buttercup mustache-mode challenger-deep-theme helm-make all-the-icons-dired all-the-icons rjsx-mode json-mode lua-mode helm-spotify-plus go-projectile jinja2-mode cyberpunk-theme go-mode jujube-theme smart-mode-line-powerline-theme smart-mode-line visual-fill-column websocket flycheck powerline evil key-chord color-theme-modern esup counsel-projectile restclient ox-reveal org-tree-slide epresent color-moccur xterm-color nlinum-relative company-shell pandoc-mode virtualenvwrapper counsel helm-swoop groovy-mode octopress zenburn-theme yaml-mode which-key wgrep-ag web-mode w3m use-package twittering-mode sunshine sublime-themes rainbow-mode powerline-evil mmm-mode markdown-mode magit highlight-symbol helm-projectile fullframe flycheck-package exec-path-from-shell evil-surround evil-leader evil-jumper evil-indent-textobject emmet-mode elpy dictionary color-theme-sanityinc-tomorrow bpr auto-complete ag))
 '(safe-local-variable-values '((css-indent-offset . 2) (no-byte-compile t)))
 '(writeroom-global-effects
   '(writeroom-set-alpha writeroom-set-menu-bar-lines writeroom-set-tool-bar-lines writeroom-set-vertical-scroll-bars writeroom-set-bottom-divider-width)))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((((class color) (min-colors 89)) (:foreground "#d4d4d4" :background "#000000"))))
 '(deadgrep-filename-face ((t (:foreground "gold" :underline t))))
 '(deadgrep-match-face ((t (:background "#2f2f2d" :foreground "lime green"))))
 '(italic ((t (:slant italic))))
 '(markdown-italic-face ((t (:inherit italic :underline nil :slant italic))))
 '(org-block-begin-line ((((class color) (min-colors 89)) (:inherit org-meta-line :underline t))))
 '(org-habit-alert-future-face ((t (:background "orange2"))))
 '(org-habit-clear-face ((t (:background "#40424a" :foreground "lime green"))))
 '(org-habit-clear-future-face ((((class color) (min-colors 89)) (:background "#40424a"))))
 '(org-habit-overdue-face ((((class color) (min-colors 89)) (:background "#ffb4ac" :foreground "#4f4340"))))
 '(org-habit-overdue-future-face ((t (:background "OrangeRed3"))))
 '(org-habit-ready-face ((((class color) (min-colors 89)) (:background "#3d454c" :foreground "#8ac6f2"))))
 '(org-habit-ready-future-face ((t (:background "SeaGreen4"))))
 '(org-meta-line ((((class color) (min-colors 89)) (:foreground "#878777" :slant italic))))
 '(org-priority ((t (:inherit font-lock-warning-face))))
 '(org-scheduled-previously ((((class color) (min-colors 89)) (:foreground "#7ec98f"))))
 '(org-scheduled-today ((((class color) (min-colors 89)) (:foreground "#a4b5e6" :weight normal)))))
