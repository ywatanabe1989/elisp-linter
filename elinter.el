;;; -*- coding: utf-8; lexical-binding: t -*-
;;; Author: ywatanabe
;;; Timestamp: <2025-04-30 13:17:25>
;;; File: /home/ywatanabe/.emacs.d/lisp/elinter/elinter.el

;;; Copyright (C) 2025 Yusuke Watanabe (ywatanabe@alumni.u-tokyo.ac.jp)


(require 'elinter-register)
(require 'subr-x)

;; 1. Variables
;; ----------------------------------------

(defvar --elinter-fake-header ";; ELINTER-FAKE-HEADER"
  "Tag string used to mark positions during formatting.")

(defvar --elinter-tag "(THIS-IS-ELINTER-TAG)"
  "Tag string used to mark positions during formatting.")

(defcustom elinter-supported-modes
  '(emacs-lisp-mode lisp-mode)
  "List of major modes supported by elinter.")

;; 2. Main Function
;; ----------------------------------------

(defun elinter-lint-buffer
    ()
  "Format current elisp buffer"
  (interactive)
  (atomic-change-group
    (save-excursion
      (unless
          (and buffer-file-name
               (member
                (expand-file-name buffer-file-name)
                elinter-exclude-files))
        (let
            ((original-point
              (point)))

          ;; Ensure one empty line before def
          (--elinter-ensure-empty-line-before-def)

          ;; To the top
          (goto-char
           (point-min))

          ;; Remove any existing fake headers first
          (--elinter-remove-existing-fake-headers)

          ;; Insert fresh fake header
          (--elinter-insert-fake-header)

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
          ;; Fix closing parentheses
          (--elinter-remove-whitespaces-between-closing-parens)
          ;; Removes all tags
          (--elinter-remove-all-tags)
          ;; Removes fake header
          (--elinter-remove-fake-header)
          ;; Mark buffer
          (--elinter-indent-buffer)
          ;; Cleanup
          (--elinter-remove-the-first-empty-lines)
          ;; To the original point
          (goto-char original-point))))))

;; (defun elinter-lint-buffer ()
;;   "Format current buffer based on its major mode."
;;   (interactive)
;;   ;; Check if current mode is supported
;;   (unless (member major-mode elinter-supported-modes)
;;     (message "Elinter: %s mode not supported" major-mode)
;;     (return-from elinter-lint-buffer))

;;   ;; Save undo-tree state if enabled
;;   (when (bound-and-true-p undo-tree-mode)
;;     (undo-tree-save-state-to-register ?l))

;;   ;; Main formatting logic
;;   (save-excursion
;;     (unless (and buffer-file-name
;;                  (member (expand-file-name buffer-file-name)
;;                          elinter-exclude-files))
;;       (let ((original-point (point)))
;;         ;; Mode-specific formatting
;;         (cond
;;          ((memq major-mode '(emacs-lisp-mode lisp-mode))
;;           ;; Elisp formatting
;;           (--elinter-format-elisp-buffer))
;;          ;; Add other modes here as needed
;;          )

;;         ;; Return to original position
;;         (goto-char original-point))))

;;   ;; Restore undo-tree state if enabled
;;   (when (bound-and-true-p undo-tree-mode)
;;     (undo-tree-restore-state-from-register ?l)))

;; (defun --elinter-format-elisp-buffer ()
;;   "Format buffer containing Emacs Lisp code."
;;   ;; Existing formatting logic
;;   (--elinter-ensure-empty-line-before-def)
;;   (goto-char (point-min))
;;   (--elinter-remove-existing-fake-headers)
;;   (--elinter-insert-fake-header)
;;   ;; Main formatting loop
;;   (while (not (eobp))
;;     (when (not (eobp))
;;       (--elinter-skip-comments))
;;     (when (not (eobp))
;;       (--elinter-skip-code-block))
;;     (when (and (not (eobp))
;;                (--elinter-is-empty-line))
;;       (--elinter-insert-tag))
;;     (when (not (eobp))
;;       (delete-blank-lines))
;;     (when (not (eobp))
;;       (forward-line)))
;;   ;; Post-processing
;;   (pp-buffer)
;;   (--elinter-remove-whitespaces-between-closing-parens)
;;   (--elinter-remove-all-tags)
;;   (--elinter-remove-fake-header)
;;   (--elinter-indent-buffer)
;;   (--elinter-remove-the-first-empty-lines))

;; 3. Helper functions
;; ----------------------------------------

;; ;; Only "(def"
;; (defun --elinter-ensure-empty-line-before-def
;;     ()
;;   "Ensure empty line before each defun.
;; Adds an empty line before each defun declaration if one doesn't exist."
;;   (save-excursion
;;     (goto-char
;;      (point-min))
;;     (while
;;         (re-search-forward "^(def" nil t)
;;       (beginning-of-line)
;;       (if
;;           (=
;;            (line-number-at-pos)
;;            1)
;;           ;; At the beginning of the buffer, no need for empty line
;;           nil
;;         ;; Check previous line
;;         (save-excursion
;;           (forward-line -1)
;;           (unless
;;               (looking-at "^[[:space:]]*$")
;;             ;; Previous line is not empty, insert a blank line
;;             (end-of-line)
;;             (insert "\n"))))
;;       ;; Move to the next line after current defun
;;       (forward-line 1))))

;; update this list

(defcustom elinter-ensure-line-before-list
  '("(def" "(global-set-key" "(use-package")
  "List of regex patterns that should have an empty line before them.")

;; apply the list

(defun --elinter-ensure-empty-line-before-def
    ()
  "Ensure empty line before each pattern from elinter-ensure-line-before-list.
Adds an empty line before each matching pattern if one doesn't exist."
  (save-excursion
    (goto-char
     (point-min))
    (dolist
        (pattern elinter-ensure-line-before-list)
      (goto-char
       (point-min))
      (while
          (re-search-forward
           (concat "^" pattern)
           nil t)
        (beginning-of-line)
        (if
            (=
             (line-number-at-pos)
             1)
            ;; At the beginning of the buffer, no need for empty line
            nil
          ;; Check previous line
          (save-excursion
            (forward-line -1)
            (unless
                (looking-at "^[[:space:]]*$")
              ;; Previous line is not empty, insert a blank line
              (end-of-line)
              (insert "\n"))))
        ;; Move to the next line after current match
        (forward-line 1)))))

;; Checker
;; ----------------------------------------

(defun --elinter-is-empty-line
    ()
  "Check if current line contains only whitespace."
  (save-excursion
    (let
        ((is-empty-line
          (looking-at "^[[:space:]]*$")))
      (message "%s" is-empty-line)
      is-empty-line)))

;; Skippers
;; ----------------------------------------

;; (defun --elinter-skip-comments
;;     ()
;;   "Skip over comment blocks and move to next non-comment line."
;;   (when
;;       (looking-at "^[[:space:]]*;")
;;     (forward-line 1)
;;     (while
;;         (looking-at "^[[:space:]]*;")
;;       (forward-line 1))))

(defcustom elinter-preserve-comment-patterns
  '("^;;;###autoload" "^;; [A-Z]+-[A-Z]+-[A-Z]+:")
  "List of regex patterns for comments that should be preserved during formatting.")

(defun --elinter-skip-comments ()
  "Skip over comment blocks and move to next non-comment line.
Preserves special comments like autoload tags."
  (when (looking-at "^[[:space:]]*;")
    (let ((current-line (buffer-substring-no-properties
                         (line-beginning-position)
                         (line-end-position))))
      (dolist (pattern elinter-preserve-comment-patterns)
        (when (string-match pattern current-line)
          ;; Don't modify this line - just advance past it
          (forward-line 1)
          (return-from --elinter-skip-comments))))

    (forward-line 1)
    (while (looking-at "^[[:space:]]*;")
      (let ((current-line (buffer-substring-no-properties
                           (line-beginning-position)
                           (line-end-position))))
        (catch 'continue
          (dolist (pattern elinter-preserve-comment-patterns)
            (when (string-match pattern current-line)
              ;; Don't modify this line - just advance past it
              (forward-line 1)
              (throw 'continue t)))
          (forward-line 1))))))

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

;; Inserters
;; ----------------------------------------

(defun --elinter-insert-fake-header
    ()
  "Insert fake header at current point."
  (save-excursion
    (goto-char
     (point-min))
    (insert --elinter-fake-header "\n")))

(defun --elinter-insert-tag
    ()
  "Insert tag at current point."
  (save-excursion
    (insert --elinter-tag)))

;; Removers
;; ----------------------------------------

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

(defun --elinter-remove-existing-fake-headers
    ()
  "Remove any existing fake headers"
  (save-excursion
    (goto-char
     (point-min))
    (while
        (looking-at
         (concat "^"
                 (regexp-quote --elinter-fake-header)))
      (delete-line))))

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

(defun --elinter-remove-the-first-empty-lines
    ()
  "Remove empty lines at the beginning of buffer."
  (save-excursion
    (let
        ((orig-pos
          (point)))
      (goto-char
       (point-min))
      (while
          (--elinter-is-empty-line)
        (delete-region
         (line-beginning-position)
         (1+
          (line-end-position))))
      (goto-char orig-pos))))

(defun --elinter-remove-whitespaces-between-closing-parens
    ()
  "Fix cases where closing parenthesis is followed by newline and indented parentheses."
  (save-excursion
    (goto-char
     (point-min))
    (while
        (re-search-forward ")\n[ \t]*)" nil t)
      ;; Check that the first closing paren is not in a comment
      (save-excursion
        (goto-char
         (match-beginning 0))
        (beginning-of-line)
        (unless
            (looking-at "[ \t]*;")
          ;; When we find a match and it's not commented, delete everything between the closing parentheses
          (delete-region
           (1+
            (match-beginning 0))
           (1-
            (match-end 0))))))))

;; Indent
;; ----------------------------------------

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
;;           (lambda
;;             ()
;;             (add-hook 'before-save-hook 'elinter-lint-buffer nil t)))


(provide 'elinter)

(when
    (not load-file-name)
  (message "elinter.el loaded."
           (file-name-nondirectory
            (or load-file-name buffer-file-name))))