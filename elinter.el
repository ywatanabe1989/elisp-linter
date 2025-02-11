;;; Author: 2025-01-29 21:56:03
;;; Timestamp: <2025-01-29 21:56:03>
;;; File: /home/ywatanabe/.dotfiles/.emacs.d/lisp/elinter/elinter.el

;; 1. Main entry
;; ----------------------------------------

(defun elinter-lint-buffer
    ()
  "Format current elisp buffer"
  (interactive)
  (let
      ((original-point
        (point)))
    ;; To the top
    (goto-char
     (point-min))
    ;; Remove any existing fake headers first
    (while
        (looking-at
         (concat "^"
                 (regexp-quote --elinter-fake-header)))
      (delete-line))
    ;; Insert fresh fake header
    (insert --elinter-fake-header "\n")
    ;; Main
    (while
        (not
         (eobp))
      (when
          (not
           (eobp))
        (--elinter-skip-comments))
      (when
          (not
           (eobp))
        (--elinter-skip-code-block))
      (when
          (and
           (not
            (eobp))
           (--elinter-is-empty-line))
        (--elinter-insert-tag))
      (when
          (not
           (eobp))
        (delete-blank-lines))
      (when
          (not
           (eobp))
        (forward-line)))
    ;; Calls pp-buffer
    (pp-buffer)
    ;; Removes all tags
    (--elinter-remove-all-tags)
    ;; Removes fake header
    (--elinter-remove-fake-header)
    ;; Mark buffer
    (--elinter-indent-buffer)
    ;; To the original point
    (goto-char original-point)))

;; 2. Core functions
;; ----------------------------------------

(defun --elinter-is-empty-line
    ()
  "Check if current line contains only whitespace."
  (let
      ((is-empty-line
        (looking-at "^[[:space:]]*$")))
    (message "%s" is-empty-line)
    is-empty-line))

(defun --elinter-skip-comments
    ()
  "Skip over comment blocks and move to next non-comment line."
  (when
      (looking-at "^[[:space:]]*;")
    (forward-line 1)
    (while
        (looking-at "^[[:space:]]*;")
      (forward-line 1))))

(defun --elinter-skip-code-block
    ()
  "Skip over code block until comment or empty line is found."
  (when
      (not
       (or
        (looking-at "^[[:space:]]*;")
        (looking-at "^[[:space:]]*$")))
    (forward-line 1)
    (while
        (and
         (not
          (eobp))
         (not
          (looking-at "^[[:space:]]*;"))
         (not
          (looking-at "^[[:space:]]*$")))
      (forward-line 1))))

(defvar --elinter-fake-header ";; ELINTER-FAKE-HEADER"
  "Tag string used to mark positions during formatting.")

(defvar --elinter-tag "(THIS-IS-ELINTER-TAG)"
  "Tag string used to mark positions during formatting.")

(defun --elinter-remove-fake-header
    ()
  "Remove fake headers from buffer."
  (save-excursion
    (goto-char
     (point-min))
    (while
        (re-search-forward
         (concat "^"
                 (regexp-quote --elinter-fake-header))
         nil t)
      (delete-region
       (line-beginning-position)
       (1+
        (line-end-position))))))

(defun --elinter-insert-tag
    ()
  "Insert tag at current point."
  (insert --elinter-tag))

(defun --elinter-remove-all-tags
    ()
  "Remove all tags from buffer."
  (save-excursion
    (goto-char
     (point-min))
    (while
        (re-search-forward
         (concat "^[[:space:]]*"
                 (regexp-quote --elinter-tag)
                 "[[:space:]]*$")
         nil t)
      (replace-match ""))))

(defun --elinter-indent-buffer
    ()
  "Indent entire buffer."
  (save-excursion
    (indent-region
     (point-min)
     (point-max))))

;; ;; 3. Key Binding and Hook
;; ;; ----------------------------------------
;; (define-key emacs-lisp-mode-map
;;             (kbd "C-c C-l")
;;             'elinter-lint-buffer)
;; ;; Before saving
;; (add-hook 'emacs-lisp-mode-hook
;;           (lambda ()
;;             (add-hook 'before-save-hook 'elinter-lint-buffer nil t)))

(provide 'elinter)

(when
    (not load-file-name)
  (message "elinter.el loaded."
           (file-name-nondirectory
            (or load-file-name buffer-file-name))))
