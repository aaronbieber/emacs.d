;;; Provide settings that only work on Macs.
(require 'init-fonts)

(when (memq window-system '(mac ns))
  (add-to-list 'default-frame-alist '(font . "Menlo-14"))
  (set-face-attribute 'default t :font "Menlo-14")
  (sanityinc/set-frame-font-size 14)
  (define-key global-map (kbd "<s-return>") 'toggle-frame-fullscreen))

(provide 'init-mac)
