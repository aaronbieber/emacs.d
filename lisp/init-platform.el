;;; init-platform --- Platform-specific settings
;;; Commentary:

;;; Code:
(require 'init-fonts)

;; This must run after window setup or it seems to have no effect.
(add-hook 'window-setup-hook
          (lambda ()
            (when (eq system-type 'darwin)
              (use-package exec-path-from-shell
                :ensure t
                :config
                (exec-path-from-shell-initialize)
                (exec-path-from-shell-copy-env "GOPATH"))
              (set-face-attribute 'default nil :font "JetBrains Mono")
              (sanityinc/set-frame-font-size 14)
              (define-key global-map (kbd "<s-return>") 'toggle-frame-fullscreen))

            ;; I don't think I do this anymore (windows native?)
            (when (memq window-system '(w32))
              (set-face-attribute 'default nil :font "Hack")
              (setq epg-gpg-home-directory "c:/Users/Aaron/AppData/Roaming/GnuPG")
              (setq epg-gpg-program "c:/Users/Aaron/Programs/GnuPG/bin/gpg.exe")
              (setq epg-gpgconf-program "c:/Users/Aaron/Programs/GnuPG/bin/gpgconf.exe")
              (sanityinc/set-frame-font-size 20))

            ;; WSL/WSL2
            (when (and (eq system-type 'gnu/linux)
                       (string-match
                        "Linux.*microsoft.*Linux"
                        (shell-command-to-string "uname -a")))
              (set-face-attribute 'default nil :font "JetBrainsMono Nerd Font Mono")
              (sanityinc/set-frame-font-size 19)

              (setq browse-url-generic-program "/c/Windows/system32/cmd.exe"
                    browse-url-generic-args '("/c" "start")
                    browse-url-browser-function #'browse-url-generic)

              (set-frame-size (selected-frame) 80 40))

            ;; Using media keys when Emacs has focus rings the bell
            ;; and displays errors otherwise.
            (global-set-key (kbd "<XF86AudioRaiseVolume>") (lambda () (interactive)))
            (global-set-key (kbd "<XF86AudioLowerVolume>") (lambda () (interactive)))
            (global-set-key (kbd "<XF86AudioNext>") (lambda () (interactive)))
            (global-set-key (kbd "<XF86AudioPrev>") (lambda () (interactive)))
            (global-set-key (kbd "<XF86AudioPlay>") (lambda () (interactive)))

            (when (fboundp 'powerline-reset)
              (powerline-reset))))

(if (eq window-system 'w32)
    (setq ispell-program-name "~/hunspell/bin/hunspell.exe"))

;; Display emoji on Macs where the font is already there.
(when (memq window-system '(mac))
  (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend))

(if (not window-system)
    (progn
      (define-key function-key-map "\eOA" 'previous-line)
      (define-key function-key-map "\eOB" 'next-line)
      (define-key function-key-map "\eOC" 'forward-char)
      (define-key function-key-map "\eOD" 'backward-char)))

(provide 'init-platform)
;;; init-platform.el ends here
