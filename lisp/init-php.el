(when (maybe-require-package 'php-mode)
  (defun air--rbt-run-command (command)
    "Run an rbt COMMAND and send its output to a buffer."
    (let ((rbt-buffer (get-buffer-create "*rbt: command*"))
          (cmd (concat "rbt " command))
          (map (make-sparse-keymap)))
      (with-current-buffer rbt-buffer
        (local-set-key (kbd "q") #'(lambda () (interactive) (kill-buffer (current-buffer))))
        (shell-command cmd rbt-buffer)
        (goto-char (point-min))
        (if (search-forward "http" (point-max) t)
            (let ((url (thing-at-point 'url)))
              (if (yes-or-no-p (format "Browse to `%s'? " url))
                  (browse-url url)))))))

  (defun air-rbt-post (summary)
    (interactive "MSummary: ")
    (let ((command (concat "post --summary " (shell-quote-argument summary))))
      (message "Running `%s'..." command)
      (air--rbt-run-command command)))

  (defun air-rbt-update (id)
    (interactive "nRequest ID to update: ")
    (let ((command (concat "post -r " (shell-quote-argument (number-to-string id)))))
      (message "Running `%s'..." command)
      (air--rbt-run-command command)))

  (defun my-php-lineup-arglist-intro (langelem)
    (save-excursion
      (goto-char (cdr langelem))
      (vector (+ (current-column) (* 2 c-basic-offset)))))

  (defun my-php-lineup-arglist-close (langelem)
    (save-excursion
      (goto-char (c-langelem-pos langelem))
      (vector (current-column))))

  (defun my-php-lineup-arglist-cont-nonempty (langelem)
    "Align continued arglist lines to two times the basic offset from langelem."
    (save-excursion
      (goto-char (c-langelem-pos langelem))
      (vector (+ (current-column) (* 2 c-basic-offset)))))

  (defun my-php-lineup-statement-cont (langelem)
    "Align continued statement lines in PHP."
    (message (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
    (save-excursion
      (back-to-indentation)
      (if (search-forward "->" (line-end-position) t)
          (* 2 c-basic-offset)
        (php-lineup-string-cont langelem))))

  ;; Provide a style based on "php" that changes a couple of indent behaviors.
  (c-add-style "wf-php"
               '("php"
                 (c-basic-offset . 2)
                 (c-offsets-alist . ((arglist-intro . my-php-lineup-arglist-intro)
                                     (arglist-close . my-php-lineup-arglist-close)
                                     (arglist-cont-nonempty . my-php-lineup-arglist-cont-nonempty)
                                     (statement-cont . my-php-lineup-statement-cont)
                                     (topmost-intro-cont . my-php-lineup-statement-cont)))))

  ;; Configure things for PHP usage.
  ;; We can bring back fci-mode if we use @purcell's workaround found here:
  ;; https://github.com/alpaker/Fill-Column-Indicator/issues/21
  (defun configure-php-mode ()
    (require 'newcomment)
    (setq comment-auto-fill-only-comments 1)
    (setq auto-fill-function 'do-auto-fill)
    (setq flycheck-disabled-checkers '(php-phpmd))

    (c-set-style "wf-php")
    (turn-on-eldoc-mode)
    (highlight-symbol-mode)

    (turn-on-auto-fill)
    (set-fill-column 120)
    (add-to-list 'write-file-functions 'delete-trailing-whitespace)
    (gtags-mode t)
    (flycheck-mode)
    (yas-minor-mode t))

  (add-hook 'php-mode-hook 'configure-php-mode))

(provide 'init-php)
