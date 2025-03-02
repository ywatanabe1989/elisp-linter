;;; -*- coding: utf-8; lexical-binding: t -*-
;;; Author: ywatanabe
;;; Timestamp: <2025-02-20 08:54:45>
;;; File: /home/ywatanabe/.dotfiles/.emacs.d/lisp/elinter/elinter-register.el

;;; Copyright (C) 2024-2025 Yusuke Watanabe (ywatanabe@alumni.u-tokyo.ac.jp)

;; Variables
;; ----------------------------------------

(defgroup elinter nil
  "Automatic header and footer management."
  :prefix "elinter-"
  :group 'convenience)

(defcustom elinter-exclude-files
  '()
  "List of files to exclude from header/footer updates."
  :type
  '(repeat string)
  :group 'elinter)

;; Exclusion Functions
;; ----------------------------------------

(defun elinter-register-exclude-file
    ()
  "Add current buffer file or marked files in dired to `elinter-exclude-files`."
  (interactive)
  (if
      (derived-mode-p 'dired-mode)
      (dolist
          (file
           (dired-get-marked-files))
        (add-to-list 'elinter-exclude-files
                     (expand-file-name file))
        (message "Added %s to exclusion list" file))
    (if buffer-file-name
        (progn
          (add-to-list 'elinter-exclude-files
                       (expand-file-name buffer-file-name))
          (message "Added %s to exclusion list" buffer-file-name))
      (message "No file to register"))))

(defun elinter-unregister-exclude-file
    ()
  "Remove current buffer file or marked files in dired from `elinter-exclude-files`."
  (interactive)
  (if
      (derived-mode-p 'dired-mode)
      (dolist
          (file
           (dired-get-marked-files))
        (setq elinter-exclude-files
              (delete
               (expand-file-name file)
               elinter-exclude-files))
        (message "Removed %s from exclusion list" file))
    (if buffer-file-name
        (progn
          (setq elinter-exclude-files
                (delete
                 (expand-file-name buffer-file-name)
                 elinter-exclude-files))
          (message "Removed %s from exclusion list" buffer-file-name))
      (message "No file to unregister"))))

(defun elinter-toggle-exclude-file
    ()
  "Toggle current buffer file or marked files in dired in `elinter-exclude-files`."
  (interactive)
  (if
      (derived-mode-p 'dired-mode)
      (dolist
          (file
           (dired-get-marked-files))
        (let
            ((expanded-file
              (expand-file-name file)))
          (if
              (member expanded-file elinter-exclude-files)
              (progn
                (setq elinter-exclude-files
                      (delete expanded-file elinter-exclude-files))
                (message "Removed %s from exclusion list" file))
            (add-to-list 'elinter-exclude-files expanded-file)
            (message "Added %s to exclusion list" file))))
    (if buffer-file-name
        (let
            ((expanded-file
              (expand-file-name buffer-file-name)))
          (if
              (member expanded-file elinter-exclude-files)
              (progn
                (setq elinter-exclude-files
                      (delete expanded-file elinter-exclude-files))
                (message "Removed %s from exclusion list" buffer-file-name))
            (add-to-list 'elinter-exclude-files expanded-file)
            (message "Added %s to exclusion list" buffer-file-name)))
      (message "No file to toggle"))))

;; ;; Key Bindings
;; ;; ----------------------------------------
;; (global-set-key (kbd "C-c <delete>") 'elinter-toggle-exclude-file)

(provide 'elinter-register)

(when
    (not load-file-name)
  (message "elinter-register.el loaded."
           (file-name-nondirectory
            (or load-file-name buffer-file-name))))