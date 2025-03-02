;;; -*- coding: utf-8; lexical-binding: t -*-
;;; Author: ywatanabe
;;; Timestamp: <2025-03-03 01:16:39>
;;; File: /home/ywatanabe/.dotfiles/.emacs.d/lisp/elinter/tests/test-elinter-register.el

;;; test-elinter-register.el --- Tests for elinter-register.el -*- lexical-binding: t -*-

(require 'ert)
(require 'elinter-register)

;; Test for loadability
(ert-deftest test-elinter-register-loadable
    ()
  (should
   (featurep 'elinter-register)))

;; Test for variable initialization
(ert-deftest test-elinter-register-vars-initialized
    ()
  (should
   (boundp 'elinter-exclude-files))
  (should
   (listp elinter-exclude-files)))

;; Test for file exclusion registration
(ert-deftest test-elinter-register-exclude-file
    ()
  (let
      ((elinter-exclude-files
        '())
       (buffer-file-name "/tmp/test.el"))
    (elinter-register-exclude-file)
    (should
     (member
      (expand-file-name buffer-file-name)
      elinter-exclude-files))))

;; Test for file exclusion unregistration
(ert-deftest test-elinter-unregister-exclude-file
    ()
  (let
      ((test-file "/tmp/test.el")
       (elinter-exclude-files
        (list
         (expand-file-name "/tmp/test.el")))
       (buffer-file-name "/tmp/test.el"))
    (elinter-unregister-exclude-file)
    (should-not
     (member
      (expand-file-name test-file)
      elinter-exclude-files))))

;; Test for toggling file exclusion (adding)
(ert-deftest test-elinter-toggle-exclude-file-add
    ()
  (let
      ((elinter-exclude-files
        '())
       (buffer-file-name "/tmp/test.el"))
    (elinter-toggle-exclude-file)
    (should
     (member
      (expand-file-name buffer-file-name)
      elinter-exclude-files))))

;; Test for toggling file exclusion (removing)
(ert-deftest test-elinter-toggle-exclude-file-remove
    ()
  (let
      ((test-file "/tmp/test.el")
       (elinter-exclude-files
        (list
         (expand-file-name "/tmp/test.el")))
       (buffer-file-name "/tmp/test.el"))
    (elinter-toggle-exclude-file)
    (should-not
     (member
      (expand-file-name test-file)
      elinter-exclude-files))))

(provide 'test-elinter-register)

(when
    (not load-file-name)
  (message "test-elinter-register.el loaded."
           (file-name-nondirectory
            (or load-file-name buffer-file-name))))