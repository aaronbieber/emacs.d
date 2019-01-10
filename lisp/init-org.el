;;; init-org.el --- Set up Org Mode
;;; Commentary:

;; Basic Org Mode configuration, assuming presence of Evil & Evil Leader.

;; Defaults
(defcustom air-org-root-location "~/Dropbox/org"
  "The root location where Org files are stored."
  :type 'directory
  :group 'air-org)

;; Helper functions
(defun air-org-insert-first-link ()
  "Insert the first link in `org-stored-links', or do nothing."
  (interactive)
  (let ((link (car org-stored-links)))
    (org-insert-link nil (car link) (cadr link))))

(defun air--alist-key-match-p (list substring)
  "Return t if any key in LIST contains SUBSTRING."
  (let ((found))
    (dolist (item list)
      (if (string-match-p substring (car item))
          (setq found t)))
    found))

(defun air-org-export-top-subtree ()
  "Export the nearest parent subtree with export options.

By \"with export options\" we mean any entry with a property that
contains \"EXPORT\".

This exports as a Beamer PDF and opens it, because that's what I always do."
  (interactive)
  (let ((failed))
    (save-excursion
      (org-with-limited-levels
       (outline-previous-visible-heading 1)
       (while (and (not failed)
                   (not (air--alist-key-match-p
                         (org-entry-properties) "EXPORT")))
         (or (org-up-heading-safe)
             (setq failed t)))
       (if failed
           (message "No exportable heading found.")
         (org-open-file (org-beamer-export-to-pdf nil t)))))))

(defun air--beamer-bold (contents backend info)
  "Beamer export filter to use the correct LaTeX markup for bold.

CONTENTS BACKEND INFO are required arguments for filter functions."
  (when (eq backend 'beamer)
    (replace-regexp-in-string "\\`\\\\[A-Za-z0-9]+" "\\\\textbf" contents)))

(defun air-org-bulk-copy-headlines (&optional strip-tags)
  "Copy the headline text of the marked headlines in an agenda view.

This function is designed to be called interactively from an agenda
view with marked items.

If STRIP-TAGS is not nil, remove tags and trailing spaces from
the headlines."
  (interactive "P")
  (unless org-agenda-bulk-marked-entries (user-error "No entries are marked"))
  (let ((entries "")
        entry)
    (dolist (entry-marker (reverse org-agenda-bulk-marked-entries))
      (with-current-buffer (marker-buffer entry-marker)
        (save-excursion
          (goto-char (marker-position entry-marker))
          (when (re-search-forward org-heading-regexp (line-end-position) t)
            (setq entry (match-string-no-properties 2))
            (if strip-tags
                (setq entry (replace-regexp-in-string
                             (rx (0+ " ")
                                 (0+ (any alpha ":"))
                                 line-end)
                             "" entry)))
            (setq entries (concat entries entry "\n"))))))
    (if (length entries)
        (kill-new entries)))
  (message "Acted on %s entries%s"
           (length org-agenda-bulk-marked-entries)
           (if org-agenda-persistent-marks
               " (kept marked)" ""))
  (unless org-agenda-persistent-marks
    (org-agenda-bulk-unmark-all)))

(defun air-org-agenda-next-header ()
  "Jump to the next header in an agenda series."
  (interactive)
  (air--org-agenda-goto-header))

(defun air-org-agenda-previous-header ()
  "Jump to the previous header in an agenda series."
  (interactive)
  (air--org-agenda-goto-header t))

(defun air--org-agenda-goto-header (&optional backwards)
  "Find the next agenda series header forwards or BACKWARDS."
  (let ((pos (save-excursion
               (goto-char (if backwards
                              (line-beginning-position)
                            (line-end-position)))
               (let* ((find-func (if backwards
                                     'previous-single-property-change
                                   'next-single-property-change))
                      (end-func (if backwards
                                    'max
                                  'min))
                      (all-pos-raw (list (funcall find-func (point) 'org-agenda-structural-header)
                                         (funcall find-func (point) 'org-agenda-date-header)))
                      (all-pos (cl-remove-if-not 'numberp all-pos-raw))
                      (prop-pos (if all-pos (apply end-func all-pos) nil)))
                 prop-pos))))
    (if pos (goto-char pos))
    (if backwards (goto-char (line-beginning-position)))))

(defun air-org-helm-headings ()
  "Call `helm-org-agenda-files-headings' with a longer list of files."
  (interactive)
  (let ((org-agenda-files (list (expand-file-name "gtd/inbox.org" org-directory)
                                (expand-file-name "gtd/team.org" org-directory)
                                (expand-file-name "notes.org" org-directory))))
    (call-interactively 'helm-org-agenda-files-headings)))

(defun air--org-display-tag (tag &optional focus)
  "Display entries tagged with TAG in a fit window.

Do not make the new window current unless FOCUS is set."
  (let ((org-agenda-files (list (expand-file-name "gtd/inbox.org" org-directory)
                                (expand-file-name "gtd/team.org" org-directory)
                                (expand-file-name "notes.org" org-directory))))
    (org-tags-view nil tag))
  (fit-window-to-buffer)
  (unless focus
    (other-window 1)))

(defun air-org-display-any-tag ()
  "Display entries tagged with a tag selected interactively."
  (interactive)
  (air--org-display-tag (air--org-select-tag)))

(defun air-org-display-directs (&optional focus)
  "Display entries tagged with `direct'.

Do not make the new window current unless FOCUS is set."
  (interactive "P")
  (air--org-display-tag "direct" focus))

(defun air-org-display-managers (&optional focus)
  "Display entries tagged with `manager'.

Do not make the new window current unless FOCUS is set."
  (interactive "P")
  (air--org-display-tag "manager" focus))

(defun air-org-display-engineers (&optional focus)
  "Display entries tagged with `engineer'.

Do not make the new window current unless FOCUS is set."
  (interactive "P")
  (air--org-display-tag "engineer" focus))

(defun air-org-skip-if-not-closed-today (&optional subtree)
  "Skip entries that were not closed today.

Skip the current entry unless SUBTREE is not nil, in which case skip
the entire subtree."
  (let ((end (if subtree (save-excursion (org-end-of-subtree t))
               (save-excursion (progn (outline-next-heading) (1- (point))))))
        (today-prefix (format-time-string "%Y-%m-%d")))
    (if (save-excursion
          (and (re-search-forward org-closed-time-regexp end t)
               (string= (substring (match-string-no-properties 1) 0 10) today-prefix)))
        nil
      end)))

(defun air-org-skip-if-not-closed-this-week (&optional subtree)
  "Skip entries that were not closed this week.

Skip the current entry unless SUBTREE is not nil, in which case skip
the entire subtree."
  (let ((end (if subtree (save-excursion (org-end-of-subtree t))
               (save-excursion (progn (outline-next-heading) (1- (point)))))))
    (if (not (save-excursion (re-search-forward org-closed-time-regexp end t)))
        end
      (let* ((now (current-time))
             (closed-time (date-to-time (match-string-no-properties 1)))
             (closed-day (time-to-day-in-year closed-time))
             (closed-year (format-time-string "%Y" closed-time))
             (today-day (time-to-day-in-year now))
             (today-year (format-time-string "%Y" now))
             (today-dow (format-time-string "%w" now))
             (start-day (- today-day
                           (string-to-number today-dow)))
             (end-day (+ today-day
                         (- 6 (string-to-number today-dow)))))
        (if (and (string= closed-year today-year)
                 (>= closed-day start-day)
                 (<= closed-day end-day))
            nil
          end)))))

(defun air-org-skip-if-habit (&optional subtree)
  "Skip an agenda entry if it has a STYLE property equal to \"habit\".

Skip the current entry unless SUBTREE is not nil, in which case skip
the entire subtree."
  (let ((end (if subtree (save-excursion (org-end-of-subtree t))
                (save-excursion (progn (outline-next-heading) (1- (point)))))))
    (if (string= (org-entry-get nil "STYLE") "habit")
        end
      nil)))

(defun air-org-skip-if-priority (priority &optional subtree)
  "Skip an agenda item if it has a priority of PRIORITY.

PRIORITY may be one of the characters ?A, ?B, or ?C.

Skips the current entry unless SUBTREE is not nil."
  (let ((end (if subtree (save-excursion (org-end-of-subtree t))
                (save-excursion (progn (outline-next-heading) (1- (point))))))
        (pri-value (* 1000 (- org-lowest-priority priority)))
        (pri-current (org-get-priority (thing-at-point 'line t))))
    (if (= pri-value pri-current)
        end
      nil)))

(defun air--org-global-custom-ids ()
  "Find custom ID fields in all org agenda files."
  (let ((files (org-agenda-files))
        file
        air-all-org-custom-ids)
    (while (setq file (pop files))
      (with-current-buffer (org-get-agenda-file-buffer file)
        (save-excursion
          (save-restriction
            (widen)
            (goto-char (point-min))
            (while (re-search-forward "^[ \t]*:CUSTOM_ID:[ \t]+\\(\\S-+\\)[ \t]*$"
                                      nil t)
              (add-to-list 'air-all-org-custom-ids
                           `(,(match-string-no-properties 1)
                             ,(concat file ":" (number-to-string (line-number-at-pos))))))))))
    air-all-org-custom-ids))

(defun air--org-find-custom-id (custom-id)
  "Return the location of CUSTOM-ID."
  (let* ((all-custom-ids (air--org-global-custom-ids)))
    (let* ((val (cadr (assoc custom-id all-custom-ids)))
           (id-parts (split-string val ":"))
           (file (car id-parts))
           (line (string-to-number (cadr id-parts))))
      (with-current-buffer (org-get-agenda-file-buffer file)
        (goto-char (point-min))
        (forward-line line)
        (org-reveal)
        (org-up-element)
        (list (current-buffer) (point))))))

(defun air-org-goto-custom-id (&optional split)
  "Go to the location of a custom ID read interactively, maybe in a SPLIT."
  (interactive "P")
  (let* ((all-custom-ids (air--org-global-custom-ids))
         (custom-id (completing-read
                     "Custom ID: "
                     all-custom-ids))
         (id-location (air--org-find-custom-id custom-id)))
    (when id-location
      (let* ((buf (car id-location))
             (loc (cadr id-location)))
        (pop-to-buffer buf (if split t nil))
        (goto-char loc)
        (org-reveal)))))

(defun air-org-insert-custom-id-link ()
  "Insert an Org link to a custom ID selected interactively."
  (interactive)
  (let* ((all-custom-ids (air--org-global-custom-ids))
         (custom-id (completing-read
                     "Custom ID: "
                     all-custom-ids)))
    (when custom-id
      (let* ((val (cadr (assoc custom-id all-custom-ids)))
             (id-parts (split-string val ":"))
             (file (car id-parts))
             (line (string-to-number (cadr id-parts))))
        (org-insert-link nil (concat file "::#" custom-id) custom-id)))))

(defun air-org-nmom-capture-template ()
  "Return a Nine Minutes on Monday weekly agenda template suitable for capture."
  (let* ((deadline-timestamp (format-time-string "<%Y-%m-%d %a>"
                                                 (air-calendar-next-day-of-week 5)))
         (deadline (format "DEADLINE: %s\n\n" deadline-timestamp)))
    (concat (format "* Week %02d\n\n" (org-days-to-iso-week (org-today)))
            (concat "** TODO Care: \n" deadline
                    "** TODO Mastery: \n" deadline
                    "** TODO Recognition: \n" deadline
                    "** TODO Purpose: \n" deadline))))

(defun air-org-set-category-property (value)
  "Set the category property of the current item to VALUE."
  (interactive (list (org-read-property-value "CATEGORY")))
  (org-set-property "CATEGORY" value))

(defun air-org-insert-heading (&optional subheading)
  "Insert a heading or a subheading.

If the optional SUBHEADING is t, insert a subheading.  Inserting
headings always respects content."
  (interactive "P")
  (if subheading
      (org-insert-subheading t)
    (org-insert-heading t)))

(defun air-org-insert-thing-dwim (&optional subthing)
  "Insert a heading or list item as appropriate; indent if SUBTHING."
  (interactive "P")
  (if (org-in-item-p)
      (progn (org-insert-item)
             (if subthing (org-shiftmetaright)))
    (air-org-insert-heading subthing)))

(defun air-org-toggle-checkbox-dwim (&optional toggle-presence)
  "Toggle checkbox presence and state, when TOGGLE-PRESENCE, do that."
  (interactive "P")
  (let ((toggle-presence-prefix (if (not (org-at-item-checkbox-p))
                                    '(4)
                                  toggle-presence)))
    (setq current-prefix-arg toggle-presence-prefix)
    (call-interactively 'org-toggle-checkbox)))

(defun air-org-insert-scheduled-heading (&optional subheading)
  "Insert a new org heading scheduled for today.

Insert the new heading at the end of the current subtree if
FORCE-HEADING is non-nil."
  (interactive "P")
  (if subheading
      (org-insert-subheading t)
    (org-insert-todo-heading t t))
  (org-schedule nil (format-time-string "%Y-%m-%d")))

(defun air-org-task-capture (&optional vanilla)
  "Capture a task with my default template.

If VANILLA is non-nil, run the standard `org-capture'."
  (interactive "P")
  (if vanilla
      (org-capture)
    (org-capture nil "t")))

(defun air-org-tickler-capture (&optional vanilla)
  "Capture a new scheduled (tickler) item.

If VANILLA is non-nil, run the standard `org-capture'."
  (interactive "P")
  (if vanilla
      (org-capture)
    (org-capture nil "r")))

(defun air-org-agenda-capture (&optional vanilla)
  "Capture a task in agenda mode, using the date at point.

If VANILLA is non-nil, run the standard `org-capture'."
  (interactive "P")
  (if vanilla
      (org-capture)
    (let ((org-overriding-default-time (org-get-cursor-date)))
      (org-capture nil "t"))))

(defun air-org-agenda-toggle-date (current-line)
  "Toggle `SCHEDULED' and `DEADLINE' tag in the capture buffer."
  (interactive "P")
  (save-excursion
    (let ((search-limit (if current-line
                            (line-end-position)
                          (point-max))))

      (if current-line (beginning-of-line)
        (beginning-of-buffer))
      (if (search-forward "DEADLINE:" search-limit t)
          (replace-match "SCHEDULED:")
        (and (search-forward "SCHEDULED:" search-limit t)
             (replace-match "DEADLINE:"))))))

(defun air-org-pop-to-inbox ()
  "Open the GTD inbox Org file."
  (interactive)
  (find-file (expand-file-name "gtd/inbox.org" org-directory))
  (org-cycle '(16))
  (goto-char 1)
  (org-evil-motion-forward-heading))

(defun air-pop-to-org-vault (&optional split)
  "Visit my encrypted vault file, in the current window or a SPLIT."
  (interactive "P")
  (air--pop-to-file (expand-file-name "vault.gpg" org-directory) split))

(defun air-pop-to-org-notes (&optional split)
  "Visit my notes file, in the current window or SPLIT."
  (interactive "P")
  (air--pop-to-file (expand-file-name "notes.org" org-directory) split))

(defun air-pop-to-org-todo (&optional split)
  "Visit my TODO file, in the current window or SPLIT."
  (interactive "P")
  (air--pop-to-file (expand-file-name "gtd/inbox.org" org-directory) split))

(defun air-pop-to-org-agenda-default (&optional nosplit)
  "Pop to the default agenda in a split window unless NOSPLIT."
  (interactive "P")
  (air--pop-to-org-agenda-view "d" (not nosplit)))

(defun air-pop-to-org-agenda-review (&optional nosplit)
  "Pop to the default agenda in a split window unless NOSPLIT."
  (interactive "P")
  (air--pop-to-org-agenda-view "r" (not nosplit)))

(defun air-pop-to-org-agenda-home (&optional nosplit)
  "Pop to the personal agenda in a split unless NOSPLIT."
  (interactive "P")
  (air--pop-to-org-agenda-view "h" (not nosplit)))

(defun air--pop-to-org-agenda-view (key &optional split)
  "Visit the org agenda KEY, in the current window or a SPLIT."
  ;; I don't know why this works, but it works.
  (let ((current-prefix-arg nil))
    (org-agenda nil key))
  (when (not split)
    (delete-other-windows)))

(defun air--org-insert-list-leader-or-self (char)
  "If on column 0, insert space-padded CHAR; otherwise insert CHAR.

This has the effect of automatically creating a properly indented list
leader; like hyphen, asterisk, or plus sign; without having to use
list-specific key maps."
  (if (= (current-column) 0)
      (insert (concat " " char " "))
    (insert char)))

(defun air--org-swap-tags (tags)
  "Replace any tags on the current headline with TAGS.

The assumption is that TAGS will be a string conforming to Org Mode's
tag format specifications, or nil to remove all tags."
  (let ((old-tags (org-get-tags-string))
        (tags (if tags
                  (concat " " tags)
                "")))
    (save-excursion
      (beginning-of-line)
      (re-search-forward
       (concat "[ \t]*" (regexp-quote old-tags) "[ \t]*$")
       (line-end-position) t)
      (replace-match tags)
      (org-set-tags t))))

(defun air-org-goto-first-child ()
  "Goto the first child, even if it is invisible.

Return t when a child was found.  Otherwise don't move point and
return nil."
  (interactive)
  (let ((pos (point))
        (re (concat "^" outline-regexp))
        level)
    (when (condition-case nil (org-back-to-heading t) (error nil))
      (setq level (outline-level))
      (forward-char 1)
      (if (and (re-search-forward re nil t) (> (outline-level) level))
          (progn (goto-char (match-beginning 0)) t)
        (goto-char pos) nil))))

(defun air--org-select-tag ()
  "Interactively select or enter a single tag."
  (let ((org-last-tags-completion-table
         (if (derived-mode-p 'org-mode)
             (org-uniquify
              (delq nil (append (org-get-buffer-tags)
                                (org-global-tags-completion-table))))
           (org-global-tags-completion-table))))
    (completing-read
     "Tag: " 'org-tags-completion-function nil nil nil
     'org-tags-history)))

(defun air-org-agenda-filter-tag-interactive ()
  "Filter the agenda view by a tag selected interactively."
  (interactive)
  (if (derived-mode-p 'org-agenda-mode)
      (let* ((tag (air--org-select-tag))
             (org-tag-alist-for-agenda (list (cons tag ?z))))
        (if tag
            (org-agenda-filter-by-tag nil ?z)))
    (error "Tag filtering only works in an agenda view")))

(defun air-org-set-tags (tag)
  "Add TAG if it is not in the list of tags, remove it otherwise.

TAG is chosen interactively from the global tags completion table."
  (interactive (list (air--org-select-tag)))
  (let* ((cur-list (delq "" (org-get-tags)))
         (new-tags (mapconcat 'identity
                              (if (member tag cur-list)
                                  (delete tag cur-list)
                                (append cur-list (list tag)))
                              ":"))
         (new (if (> (length new-tags) 1) (concat " :" new-tags ":")
                nil)))
    (air--org-swap-tags new)))

;;; Code:
(use-package org
  :ensure t
  :defer t
  :commands (org-capture)
  :bind (("C-c c" .   org-capture)
         ("C-c l" .   org-store-link)
         ("C-c t n" . air-pop-to-org-notes)
         ("C-c t t" . air-pop-to-org-todo)
         ("C-c t v" . air-pop-to-org-vault)
         ("C-c t a" . air-pop-to-org-agenda)
         ("C-c t A" . org-agenda)
         ("C-c f k" . org-search-view)
         ("C-c f t" . org-tags-view)
         ("C-c f i" . air-org-goto-custom-id))
  :config
  (require 'org-protocol)
  (setq org-hide-emphasis-markers t)
  (setq org-modules
        '(org-bbdb org-bibtex org-docview org-habit org-info org-w3m))
  (setq org-todo-keywords
        '((sequence "TODO" "WAITING(!)" "SOMEDAY(!)" "|" "DONE(!)" "CANCELED(!)")
          (sequence "IDEA")))
  (setq org-blank-before-new-entry '((heading . t)
                                     (plain-list-item . t)))
  (setq org-capture-templates
        `(("t" "An incoming GTD item." entry
           (file "gtd/inbox.org")
           ,(concat "* IDEA %?\n"
                    ":PROPERTIES:\n"
                    ":ORDERED:  t\n"
                    ":CREATED:  %u\n"
                    ":END:\n")
           :empty-lines 1)

          ("h" "An incoming personal GTD item." entry
           (file "personal/inbox.org")
           ,(concat "* %?\n"
                    ":PROPERTIES:\n"
                    ":ORDERED:  t\n"
                    ":CREATED:  %u\n"
                    ":END:\n")
           :empty-lines 1)

        ("r" "A Reminder (tickler)." entry
         (file "gtd/tickler.org")
         "* %?\nSCHEDULED: %^t"
         :empty-lines 1)

        ("l" "A link to read later." entry
         (file "gtd/reading.org")
         ,(concat "* TODO %:annotation\n"
                  ":PROPERTIES:\n"
                  ":CREATED:  %u\n"
                  ":END:\n\n"
                  "%i")
         :empty-lines 1)

        ("n" "A note." entry
         (file "notes.org")
         ,(concat "* %?\n"
                  ":PROPERTIES:\n"
                  ":CREATED:  %u\n"
                  ":END:\n\n"))

        ("o" "A personal note." entry
         (file "personal/notes.org")
         ,(concat "* %?\n"
                  ":PROPERTIES:\n"
                  ":CREATED:  %u\n"
                  ":END:\n\n"))))

  (setq org-directory
        (if (file-directory-p (expand-file-name "~/Dropbox (personal)"))
            "~/Dropbox (personal)/org"
          "~/Dropbox/org"))
  (setq org-default-notes-file (expand-file-name "gtd/inbox.org" org-directory))

  ;; Logging of state changes
  (setq org-log-done (quote time))
  (setq org-log-redeadline (quote time))
  (setq org-log-reschedule (quote time))
  (setq org-log-into-drawer t)

  (setq org-pretty-entities t)
  (setq org-insert-heading-respect-content t)
  (setq org-ellipsis " …")
  (setq org-export-initial-scope 'subtree)
  (setq org-export-with-section-numbers nil)
  (setq org-use-tag-inheritance nil) ;; Use the list form, which happens to be blank
  (setq org-todo-keyword-faces
        '(("OPEN" . org-done)
          ("PAUSED" . org-upcoming-deadline)))

  ;; Agenda configuration
  (setq org-agenda-text-search-extra-files '(agenda-archives))
  (setq org-agenda-files (list (expand-file-name "gtd/inbox.org" org-directory)
                               (expand-file-name "gtd/team.org" org-directory)))
  (setq org-refile-targets `((,(expand-file-name "notes.org" org-directory) :maxlevel . 2)
                             (,(expand-file-name "gtd/inbox.org" org-directory) :maxlevel . 2)
                             (,(expand-file-name "gtd/someday.org" org-directory) :maxlevel . 2)
                             (,(expand-file-name "gtd/tickler.org" org-directory) :maxlevel . 2)))
  (setq org-refile-use-outline-path 'file)
  (setq org-refile-allow-creating-parent-nodes 'confirm)
  (setq org-outline-path-complete-in-steps nil)
  (setq org-agenda-time-grid '((daily today require-timed)
                               ""
                               (800 1000 1200 1400 1600)))
  (setq org-enforce-todo-dependencies t)
  (setq org-agenda-dim-blocked-tasks t)
  (setq org-tag-alist '(("@cal" . ?c)
                        ("@home" . ?h)))
  (setq org-agenda-skip-scheduled-if-done t)

  (setq org-agenda-custom-commands
        '(("d" "GTD immediate tasks"
           ((todo "TODO"
                  ((org-agenda-skip-function '(or (air-org-skip-if-habit)
                                                  (org-agenda-skip-if nil '(scheduled
                                                                            deadline))))
                   (org-agenda-overriding-header "Immediate tasks")
                   (org-agenda-files (list (expand-file-name "gtd/inbox.org" org-directory)
                                           (expand-file-name "notes.org" org-directory)))))
            (todo "WAITING"
                  ((org-agenda-skip-function 'air-org-skip-if-habit)
                   (org-agenda-overriding-header "Waiting for")
                   (org-agenda-files (list (expand-file-name "gtd/inbox.org" org-directory)))))
            (agenda ""
                    ((org-agenda-span 1)
                     (org-agenda-use-time-grid nil)
                     (org-agenda-files (list (expand-file-name "gtd/inbox.org" org-directory)
                                             (expand-file-name "gtd/team.org" org-directory)
                                             (expand-file-name "gtd/tickler.org" org-directory)
                                             (expand-file-name "diary.org" org-directory))))))
           ((org-agenda-compact-blocks t)))

          ("h" "Home/personal tasks"
           ((todo "TODO"
                       ((org-agenda-skip-function '(or (air-org-skip-if-habit)
                                                       (org-agenda-skip-if nil '(scheduled))))
                        (org-agenda-overriding-header "Immediate tasks")
                        (org-agenda-files (list (expand-file-name "personal/inbox.org" org-directory)))))))

          ("r" "Inbox review"
           ((agenda "" ((org-agenda-span 8)
                        (org-agenda-files (list (expand-file-name "gtd/inbox.org" org-directory)))))
            (stuck "" ((org-stuck-projects
                        '("+LEVEL=1/-DONE-CANCELED"
                          ("TODO" "WAITING" "SOMEDAY") nil ""))
                       (org-agenda-overriding-header (concat "Stuck projects and new items"
                                                             (make-string 72 ?-)))
                       (org-agenda-files (list (expand-file-name "gtd/inbox.org" org-directory)))))
            (todo "SOMEDAY"
                  ((org-agenda-overriding-header (concat "Maybe someday is today... "
                                                         (make-string 74 ?-)))))
            (todo "" ((org-agenda-files (list (expand-file-name "gtd/reading.org" org-directory)))
                      (org-agenda-overriding-header (concat "Reading list "
                                                            (make-string 87 ?-))))))
           ((org-agenda-compact-blocks t)))

          ("e" "Personal inbox review"
           ((agenda "" ((org-agenda-span 8)
                        (org-agenda-files (list (expand-file-name "personal/inbox.org" org-directory)))))
            (stuck "" ((org-stuck-projects
                        '("+LEVEL=1/-DONE-CANCELED"
                          ("TODO" "WAITING" "SOMEDAY") nil ""))
                       (org-agenda-overriding-header (concat "Stuck projects and new items"
                                                             (make-string 72 ?-)))
                       (org-agenda-files (list (expand-file-name "personal/inbox.org" org-directory)))))
            (todo "SOMEDAY"
                  ((org-agenda-overriding-header (concat "Maybe someday is today... "
                                                         (make-string 74 ?-)))
                   (org-agenda-files (list (expand-file-name "personal/inbox.org" org-directory))))))
           ((org-agenda-compact-blocks t)))))

  (add-to-list 'org-structure-template-alist
               (list "p" (concat ":PROPERTIES:\n"
                                 "?\n"
                                 ":END:")))

  (add-to-list 'org-structure-template-alist
               (list "eb" (concat ":EXPORT_FILE_NAME: ?\n"
                                  ":EXPORT_TITLE:\n"
                                  ":EXPORT_BEAMER_HEADER: \\subtitle{}\n"
                                  ":EXPORT_AUTHOR: Aaron Bieber\n"
                                  ":EXPORT_OPTIONS: H:1 toc:nil\n"
                                  ":EXPORT_BEAMER_THEME: wayfair\n"
                                  ":EXPORT_LATEX_CLASS: beamer")))

  (add-to-list 'org-structure-template-alist
               (list "eh" (concat ":EXPORT_FILE_NAME: ?\n"
                                  ":EXPORT_TITLE:\n"
                                  ":EXPORT_OPTIONS: toc:nil html-postamble:nil num:nil")))

  (set-face-attribute 'org-upcoming-deadline nil :foreground "gold1")

  (defun air--org-element-motion (count)
    "Return the bounds of an element; traverse upward COUNT levels."
    (save-excursion
      ;; get to the top of the tree
      (org-with-limited-levels
       (cond ((org-at-heading-p) (beginning-of-line))
             ((org-before-first-heading-p) (user-error "Not in a subtree"))
             (t (outline-previous-visible-heading 1))))

      (decf count)
      (when count (while (and (> count 0) (org-up-heading-safe)) (decf count)))

      ;; extract the beginning and end of the tree
      (let* ((element (org-element-at-point))
             (begin (org-element-property :begin element))
             (end (org-element-property :end element)))
        (list end begin))))

  (evil-define-text-object evil-org-outer-element (count &optional beg end type)
    "One whole org element, from headline to final newline."
    :type line
    (air--org-element-motion count))

  (evil-define-text-object evil-org-inner-element (count &optional beg end type)
    "An Org subtree, minus its header and concluding line break.  Uses code from `org-mark-subtree`"
    :type line
    (let* ((outer-points (air--org-element-motion count))
           (outer-begin (cadr outer-points))
           (outer-end (car outer-points))
           (begin (save-excursion
                    (goto-char outer-begin)
                    (next-line)
                    (while (and (< (point) outer-end)
                                (string-match-p "^\\s-*$"
                                                (buffer-substring (line-beginning-position)
                                                                  (line-end-position))))
                      (forward-line 1))
                    (point)))
           (end (save-excursion
                  (goto-char outer-end)
                  (backward-char 1)
                  (while (and (> (point) outer-begin)
                              (string-match-p "^\\s-*$"
                                              (buffer-substring (line-beginning-position)
                                                                (line-end-position))))
                    (forward-line -1))
                  (goto-char (line-end-position))
                  (point))))
      (list end begin)))

  (define-key evil-outer-text-objects-map "*" 'evil-org-outer-element)
  (define-key evil-inner-text-objects-map "*" 'evil-org-inner-element)

  (evil-leader/set-key-for-mode 'org-mode
    "$"  'org-archive-subtree
    "a"  'org-agenda
    "c"  'air-org-set-category-property
    "d"  'org-deadline
    "ns" 'org-narrow-to-subtree
    "p"  'org-set-property
    "s"  'org-schedule
    "t"  'air-org-set-tags)

  (add-hook 'org-agenda-mode-hook
            (lambda ()
              (setq org-habit-graph-column 50)
              (define-key org-agenda-mode-map (kbd "@")   'air-org-agenda-filter-tag-interactive)
              (define-key org-agenda-mode-map (kbd "/")   'counsel-grep-or-swiper)
              (define-key org-agenda-mode-map (kbd "H")   'beginning-of-buffer)
              (define-key org-agenda-mode-map (kbd "J")   'air-org-agenda-next-header)
              (define-key org-agenda-mode-map (kbd "K")   'air-org-agenda-previous-header)
              (define-key org-agenda-mode-map (kbd "M")   'org-agenda-bulk-unmark)
              (define-key org-agenda-mode-map (kbd "R")   'org-revert-all-org-buffers)
              (define-key org-agenda-mode-map (kbd "c")   'air-org-agenda-capture)
              (define-key org-agenda-mode-map (kbd "j")   'org-agenda-next-item)
              (define-key org-agenda-mode-map (kbd "k")   'org-agenda-previous-item)
              (define-key org-agenda-mode-map (kbd "n")   'org-agenda-next-date-line)
              (define-key org-agenda-mode-map (kbd "p")   'org-agenda-previous-date-line)
              (define-key org-agenda-mode-map (kbd "u")   'org-agenda-undo)
              (define-key org-agenda-mode-map (kbd "y")   'air-org-bulk-copy-headlines)
              (define-key org-agenda-mode-map (kbd "RET") 'org-agenda-switch-to)

              (define-prefix-command 'air-org-run-shortcuts)
              (define-key air-org-run-shortcuts "a" (tiny-menu-run-item "org-agendas"))
              (define-key air-org-run-shortcuts "c" (tiny-menu-run-item "org-captures"))
              (define-key air-org-run-shortcuts "f" (tiny-menu-run-item "org-files"))
              (define-key air-org-run-shortcuts "l" (tiny-menu-run-item "org-links"))
              (define-key air-org-run-shortcuts "t" (tiny-menu-run-item "org-things"))
              (define-key org-agenda-mode-map (kbd "\\") air-org-run-shortcuts)))

  ;; This is the hook called after a TODO or state change note capture
  ;; window has been configured. We use it here simply to enter insert
  ;; mode.
  (add-hook 'org-log-buffer-setup-hook
            (lambda ()
              (evil-insert-state)))

  (add-hook 'org-capture-mode-hook
            (lambda ()
              (evil-define-key '(normal insert) org-capture-mode-map (kbd "C-d") 'air-org-agenda-toggle-date)
              (evil-define-key 'normal org-capture-mode-map "+" 'org-priority-up)
              (evil-define-key 'normal org-capture-mode-map "-" 'org-priority-down)
              (evil-define-key '(normal insert) org-capture-mode-map (kbd "C-=" ) 'org-priority-up)
              (evil-define-key '(normal insert) org-capture-mode-map (kbd "C--" ) 'org-priority-down)
              ;; We have to do it like this because `org-capture-mode' is a
              ;; minor mode, thus `evil-emacs-state-modes' has no effect.
              ;; Recommendation from https://emacs.stackexchange.com/questions/10732/start-in-insert-state-based-on-minor-mode
              (evil-insert-state)))

  (add-hook 'org-mode-hook
            (lambda ()
              ;; Special plain list leader inserts
              (dolist (char '("+" "-"))
                (define-key org-mode-map (kbd char)
                  `(lambda ()
                    (interactive)
                    (air--org-insert-list-leader-or-self ,char))))

              ;; Normal maps
              (define-key org-mode-map (kbd "C-c d")      (lambda ()
                                                            (interactive) (air-org-agenda-toggle-date t)))
              (define-key org-mode-map (kbd "C-c ,")      'org-time-stamp-inactive)
              (define-key org-mode-map (kbd "C-|")        'air-org-insert-scheduled-heading)
              (define-key org-mode-map (kbd "<C-return>") 'air-org-insert-thing-dwim)
              (define-key org-mode-map (kbd "C-\\")       'air-org-insert-heading)

              (define-key org-mode-map (kbd "C-<")        'org-shiftmetaleft)
              (define-key org-mode-map (kbd "C->")        'org-shiftmetaright)

              (define-key org-mode-map (kbd "C-c SPC")    'air-org-export-top-subtree)

              (define-key org-mode-map (kbd "s-r")        (tiny-menu-run-item "reverts"))
              (define-key org-mode-map (kbd "C-c C-l")    (tiny-menu-run-item "org-links"))

              ;; These are set as evil keys because they conflict with
              ;; existing commands I don't use, or are superseded by
              ;; some evil function that org-mode-map is shadowed by.
              (defun complete-or-org-cycle ()
                "Call `company-complete' then `org-cycle'."
                (interactive)
                (or (and (looking-back "\\w" (line-beginning-position))
                         (or (org-try-structure-completion)
                             (company-complete)))
                    (org-cycle)))
              (evil-define-key 'normal org-mode-map (kbd "<tab>") 'org-cycle)
              (evil-define-key 'insert org-mode-map (kbd "<tab>") 'complete-or-org-cycle)

              (evil-define-key 'normal org-mode-map (kbd "C-,")   'org-metaleft)
              (evil-define-key 'normal org-mode-map (kbd "C-.")   'org-metaright)

              (evil-define-key 'insert org-mode-map (kbd "C-,")   'org-metaleft)
              (evil-define-key 'insert org-mode-map (kbd "C-.")   'org-metaright)

              (evil-define-key 'normal org-mode-map (kbd "C-S-l") 'org-shiftright)
              (evil-define-key 'normal org-mode-map (kbd "C-S-h") 'org-shiftleft)

              (evil-define-key 'insert org-mode-map (kbd "C-S-l") 'org-shiftright)
              (evil-define-key 'insert org-mode-map (kbd "C-S-h") 'org-shiftleft)

              (evil-define-key 'normal org-mode-map (kbd "[[")    'air-org-toggle-checkbox-dwim)

              ;; Navigation
              (define-key org-mode-map (kbd "M-h") 'org-up-element)
              (define-key org-mode-map (kbd "M-j") 'org-forward-heading-same-level)
              (define-key org-mode-map (kbd "M-k") 'org-backward-heading-same-level)
              (define-key org-mode-map (kbd "M-l") 'air-org-goto-first-child)

              ;; "gh" goes up a level, and is defined by org-evil-mode.
              ;; "gH" goes to the top level, and is defined by org-evil-mode.
              (evil-define-key 'normal org-mode-map (kbd "gl") 'air-org-goto-first-child)

              ;; Settings for all Org-derived modes
              (setq show-trailing-whitespace t)

              (require 'ox)
              (require 'ox-beamer)
              (setf org-export-dispatch-use-expert-ui t)
              (add-to-list 'org-export-filter-bold-functions 'air--beamer-bold)

              ;; Settings for non-agenda modes only
              (when (not (eq major-mode 'org-agenda-mode))
                (if (buffer-file-name)
                    (and (require 'periodic-commit-minor-mode)
                         (periodic-commit-minor-mode t)))
                (setq fill-column 100)
                (org-evil-mode)
                (visual-line-mode)
                (visual-fill-column-mode)
                (flyspell-mode)
                (org-indent-mode)))))

(use-package org-evil
  :ensure t
  :config
  (evil-define-minor-mode-key 'normal 'org-evil-heading-mode
    "@" 'org-refile)
  (evil-define-minor-mode-key 'normal 'org-evil-heading-mode
    "#" 'org-add-note))

(use-package org-bullets
  :ensure t
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))
  (setq org-bullets-bullet-list '("•")))

(provide 'init-org)
;;; init-org.el ends here
