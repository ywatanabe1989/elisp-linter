<!-- ---
!-- Timestamp: 2025-01-26 21:11:24
!-- Author: ywatanabe
!-- File: /home/ywatanabe/proj/lint-elisp/README.md
!-- --- -->

# elinter

A simple Emacs package for formatting Elisp code with consistent style.

## Installation

1. Copy `elinter.el` to your Emacs load path
2. Add to your init file:

```elisp
(require 'elinter)
```

## Usage

`M-x elinter-lint--buffer`

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

## Contact

Yusuke Watanabe (ywtanabe@alumini.u-tokyo.ac.jp)


<!-- EOF -->