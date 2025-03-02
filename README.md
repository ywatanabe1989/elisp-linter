<!-- ---
!-- Timestamp: 2025-03-03 01:26:23
!-- Author: ywatanabe
!-- File: /home/ywatanabe/.dotfiles/.emacs.d/lisp/elinter/README.md
!-- --- -->

# ELisp Linter

[![Build Status](https://github.com/ywatanabe1989/elisp-linter/workflows/tests/badge.svg)](https://github.com/ywatanabe1989/elisp-linter/actions)

# Example
[`elinter.el`](./elinter.el)

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

## Contact

Yusuke Watanabe (ywtanabe@alumni.u-tokyo.ac.jp)

<!-- EOF -->