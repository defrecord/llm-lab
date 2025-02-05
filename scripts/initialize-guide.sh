#!/usr/bin/env bash

# Enable error handling
set -euo pipefail

# Initialize a new guide based on template
initialize_guide() {
    local tool="$1"
    local output_dir="$2"
    local template="templates/guide-template.org"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Process template with variable substitution
    sed "s/\${tool}/$tool/g" "$template" > "$output_dir/README.org"
    
    # Add tool-specific header args if needed
    case "$tool" in
        "python"|"pytest")
            echo "#+PROPERTY: header-args:python :session *$tool*" >> "$output_dir/README.org"
            ;;
        "bash"|"sh")
            echo "#+PROPERTY: header-args:sh :session *$tool*" >> "$output_dir/README.org"
            ;;
    esac
}

# Check arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <tool-name> <output-directory>"
    exit 1
fi

initialize_guide "$1" "$2"