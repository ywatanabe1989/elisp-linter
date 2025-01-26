;;; -*- coding: utf-8; lexical-binding: t -*-
;;; Author: 2025-01-26 21:10:35
;;; Timestamp: <2025-01-26 21:10:35>
;;; File: /home/ywatanabe/proj/lint-elisp/elinter.el

;; 1. Main entry
;; ----------------------------------------
(defun elinter-lint-buffer ()
  "Format current elisp buffer"
  (interactive)
  (let ((original-point (point)))

    ;; To the top
    (goto-char (point-min))

    ;; Main
    (while (not (eobp))

      (when (not (eobp))
        (--elinter-skip-comments))

      (when (not (eobp))
        (--elinter-skip-code-block))

      (when (and (not (eobp)) (--elinter-is-empty-line))
        (--elinter-insert-newline))

      (when (not (eobp))
        (delete-blank-lines))

      (when (not (eobp))
        (forward-line)))

    ;; To the original point
    (goto-char original-point)))

;; 2. Core functions
;; ----------------------------------------
(defun --elinter-insert-newline ()
  "Insert tag at current point."
  (interactive)
  (insert "\n"))

(defun --elinter-is-empty-line ()
  "Check if current line contains only whitespace."
  (interactive)
  (let ((is-empty-line (looking-at "^[[:space:]]*$")))
    (message "%s" is-empty-line)
    is-empty-line))

(defun --elinter-skip-comments ()
  "Skip over comment blocks and move to next non-comment line."
  (interactive)
  (when (looking-at "^[[:space:]]*;")
    (forward-line 1)
    (while (looking-at "^[[:space:]]*;")
      (forward-line 1))))

(defun --elinter-skip-code-block ()
  "Skip over code block until comment or empty line is found."
  (interactive)
  (when (not (or (looking-at "^[[:space:]]*;")
                 (looking-at "^[[:space:]]*$")))
    (forward-line 1)
    (while (and (not (eobp))
                (not (looking-at "^[[:space:]]*;"))
                (not (looking-at "^[[:space:]]*$")))
      (forward-line 1))))

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
