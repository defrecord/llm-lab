#!/bin/bash
set -euo pipefail

register_template() {
    local name=$1
    local system=$2
    local extract=${3:-true}

    if [ "$extract" = true ]; then
        llm --system "$system" --extract --save "$name"
    else
        llm --system "$system" --save "$name"
    fi
}

# Register language templates
register_template "python-function" "Write a clean, well-documented Python function that follows PEP 8 style guide. Include type hints, docstring with parameters and return value, and example usage in comments."

register_template "js-function" "Write a modern JavaScript function using ES6+ features. Include JSDoc documentation with parameters, return type, and example usage."

register_template "rust-function" "Write a safe Rust function with proper error handling. Include documentation comments, type annotations, and example usage."

register_template "go-function" "Write an idiomatic Go function following Go style conventions. Include documentation comments and example usage."

register_template "clojure-function" "Write a pure Clojure function following functional programming principles. Include docstring with specs, parameters, return value, and example usage."

register_template "scheme-function" "Write a Scheme function following R6RS conventions. Include documentation with parameters, return value, and example usage."

register_template "elisp-function" "Write an Emacs Lisp function following elisp conventions. Include docstring with interactive form if needed, parameters, return value, and example usage."
