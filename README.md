<!-- ---
!-- Timestamp: 2025-01-26 21:54:47
!-- Author: ywatanabe
!-- File: /home/ywatanabe/proj/elinter/README.md
!-- --- -->

# elinter

A simple linter for Emacs Lisp that enforces consistent formatting.

## Features

- Normalizes blank lines between code blocks
- Proper indentation
- Pretty-prints s-expressions

## Installation

1. Copy `elinter.el` to your Emacs load path
2. Add to your init file:

```elisp
(require 'elinter)
```

## Usage

- `M-x elinter-lint-buffer` to format current buffer
- Or use key binding/auto-save (see Configurations)

## Configurations
``` elisp
;; Key Binding
(define-key emacs-lisp-mode-map
            (kbd "C-c C-l")
            'elinter-lint-buffer)

;; Before Saving Hook
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (add-hook 'before-save-hook 'elinter-lint-buffer nil t)))
```

## Linted File as an Example
```elisp
;;; -*- coding: utf-8; lexical-binding: t -*-
;;; Author: 2025-01-26 21:49:46
;;; Timestamp: <2025-01-26 21:49:46>
;;; File: /home/ywatanabe/proj/elinter/elinter.el

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

(defvar --elinter-tag "THIS-IS-ELINTER-TAG)"
  "Tag string used to mark positions during formatting.")

(defun --elinter-insert-tag
    ()
  "Insert tag at current point."
  (insert --elinter-tag))

(defun --elinter-remove-all-tags
    ()
  "Remove all tags from buffer."
  (save-excursion
    (let*
        ((orig-pos
          (point))
         (tag-value
          (symbol-value '--elinter-tag))
         (defvar-pos
          (save-excursion
            (goto-char
             (point-min))
            (search-forward "(defvar --elinter-tag" nil t))))
      (goto-char orig-pos)
      (goto-char
       (point-min))
      (while
          (search-forward tag-value nil t)
        (unless
            (save-excursion
              (goto-char
               (match-beginning 0))
              (looking-back "(defvar --elinter-tag[[:space:]\n]*\"" 100))
          (replace-match ""))))))

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
```

## Contact

Yusuke Watanabe (ywtanabe@alumni.u-tokyo.ac.jp)


<!-- EOF -->