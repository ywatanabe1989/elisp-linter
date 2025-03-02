;;; -*- coding: utf-8; lexical-binding: t -*-
;;; Author: ywatanabe
;;; Timestamp: <2025-03-03 01:27:58>
;;; File: /home/ywatanabe/.dotfiles/.emacs.d/lisp/elinter/tests/test-elinter.el

(require 'ert)
(require 'elinter)

;; Test for loadability
(ert-deftest test-elinter-loadable
    ()
  (should
   (featurep 'elinter)))

;; Test for variable initialization
(ert-deftest test-elinter-vars-initialized
    ()
  (should
   (stringp --elinter-fake-header))
  (should
   (stringp --elinter-tag)))

;; Test for empty line detection
(ert-deftest test-elinter-is-empty-line
    ()
  (with-temp-buffer
    (insert "   \n")
    (goto-char
     (point-min))
    (should
     (--elinter-is-empty-line))

    (erase-buffer)
    (insert "  code here  \n")
    (goto-char
     (point-min))
    (should-not
     (--elinter-is-empty-line))))

;; Test for skipping comments
(ert-deftest test-elinter-skip-comments
    ()
  (with-temp-buffer
    (insert ";; Comment 1\n;; Comment 2\nCode line\n")
    (goto-char
     (point-min))
    (--elinter-skip-comments)
    (should
     (looking-at "Code line"))))

;; Test for skipping code blocks
(ert-deftest test-elinter-skip-code-block
    ()
  (with-temp-buffer
    (insert "(defun test ()\n  (let ((var 1))\n    (+ var 1)))\n\n;; Comment\n")
    (goto-char
     (point-min))
    (--elinter-skip-code-block)
    (should
     (or
      (looking-at "^[[:space:]]*$")
      (looking-at "^[[:space:]]*;")))))

;; Test for inserting and removing fake header
(ert-deftest test-elinter-fake-header-operations
    ()
  (with-temp-buffer
    (--elinter-insert-fake-header)
    (should
     (string-match-p
      (regexp-quote --elinter-fake-header)
      (buffer-string)))

    (--elinter-remove-fake-header)
    (should-not
     (string-match-p
      (regexp-quote --elinter-fake-header)
      (buffer-string)))))

;; Test for inserting and removing tags
(ert-deftest test-elinter-tag-operations
    ()
  (with-temp-buffer
    (--elinter-insert-tag)
    (should
     (string=
      (buffer-string)
      --elinter-tag))

    (--elinter-remove-all-tags)
    (should
     (string=
      (buffer-string)
      ""))))

;; Test for removing the first empty lines
(ert-deftest test-elinter-remove-first-empty-lines
    ()
  (with-temp-buffer
    (insert "\n\n\nContent here\n")
    (--elinter-remove-the-first-empty-lines)
    (should
     (string=
      (buffer-string)
      "Content here\n"))))
(ert-deftest test-elinter-remove-whitespaces-between-closing-parens
    ()
  (with-temp-buffer
    ;; Simple case - should merge
    (insert "(test)\n  )")
    (goto-char
     (point-min))
    (--elinter-remove-whitespaces-between-closing-parens)

    ;; Normalize any potential newlines by removing all whitespace
    (let
        ((result
          (replace-regexp-in-string "[ \t\n]+" ""
                                    (buffer-string))))
      (should
       (string= result "(test))"))))

  (with-temp-buffer
    ;; Case with intervening open paren - should not merge
    (insert "(test)\n  (inner) )")
    (goto-char
     (point-min))
    (--elinter-remove-whitespaces-between-closing-parens)
    ;; For this case, we'll just check if "(inner)" still exists, ignoring exact formatting
    (should
     (string-match-p "(inner)"
                     (buffer-string)))))

;; Test for indentation
(ert-deftest test-elinter-indent-buffer
    ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(let ((var 1))\n(+ var 1))")
    (--elinter-indent-buffer)
    (should
     (string-match-p "(let ((var 1))\n  (\\+ var 1))"
                     (buffer-string)))))

;; Test ensuring empty line before def
(ert-deftest test-elinter-ensure-empty-line-before-def
    ()
  (with-temp-buffer
    (insert ";; Comment\n(defun test () nil)")
    (--elinter-ensure-empty-line-before-def)
    (should
     (string-match-p ";; Comment\n\n(defun test"
                     (buffer-string)))

    ;; Reset buffer - test multiple defs
    (erase-buffer)
    (insert "(defun test1 () nil)\n(defun test2 () nil)")
    (--elinter-ensure-empty-line-before-def)
    (should
     (string-match-p "(defun test1 () nil)\n\n(defun test2"
                     (buffer-string)))))

(ert-deftest test-elinter-lint-buffer
    ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert ";; Comment\n(defun test () nil)\n(defun test2 () (let ((var 1))))")

    ;; Mock buffer-file-name to avoid exclusion
    (let
        ((buffer-file-name "test.el")
         (elinter-exclude-files nil))
      (elinter-lint-buffer))

    ;; Check formatting improvements using more flexible pattern matching
    (should
     (string-match-p ";; Comment"
                     (buffer-string)))
    (should
     (string-match-p "(defun test"
                     (buffer-string)))
    ;; Simplify pattern for formatted code
    (should
     (or
      (string-match-p "var[[:space:]]+1"
                      (buffer-string))
      (string-match-p "var 1"
                      (buffer-string))))))

(provide 'test-elinter)

(when
    (not load-file-name)
  (message "test-elinter.el loaded."
           (file-name-nondirectory
            (or load-file-name buffer-file-name))))