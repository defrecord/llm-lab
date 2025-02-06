(when (version< emacs-version "29.1")
  (error "This configuration requires Emacs 29.1 or later"))
(sqlite-available-p)
