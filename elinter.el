;;; -*- coding: utf-8; lexical-binding: t -*-
;;; Author: ywatanabe
;;; Timestamp: <2025-03-03 01:17:22>
;;; File: /home/ywatanabe/.dotfiles/.emacs.d/lisp/elinter/elinter.el

;;; Copyright (C) 2024-2025 Yusuke Watanabe (ywatanabe@alumni.u-tokyo.ac.jp)

(require 'elinter-register)

;; 1. Variables
;; ----------------------------------------

(defvar --elinter-fake-header ";; ELINTER-FAKE-HEADER"
  "Tag string used to mark positions during formatting.")

(defvar --elinter-tag "(THIS-IS-ELINTER-TAG)"
  "Tag string used to mark positions during formatting.")

;; 2. Main Function
;; ----------------------------------------

(defun elinter-lint-buffer
    ()
  "Format current elisp buffer"
  (interactive)
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
      (goto-char original-point))))

;; 3. Helper functions
;; ----------------------------------------

(defun --elinter-ensure-empty-line-before-def
    ()
  "Ensure empty line before each defun.
Adds an empty line before each defun declaration if one doesn't exist."
  (save-excursion
    (goto-char
     (point-min))
    (while
        (re-search-forward "^(def" nil t)
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
      ;; Move to the next line after current defun
      (forward-line 1))))

;; Checker
;; ----------------------------------------

(defun --elinter-is-empty-line
    ()
  "Check if current line contains only whitespace."
  (let
      ((is-empty-line
        (looking-at "^[[:space:]]*$")))
    (message "%s" is-empty-line)
    is-empty-line))

;; Skippers
;; ----------------------------------------

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
  (insert --elinter-tag))

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
  ;; Remove any existing fake headers first
  (while
      (looking-at
       (concat "^"
               (regexp-quote --elinter-fake-header)))
    (delete-line)))

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
    (goto-char orig-pos)))

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
     (point-min))))

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