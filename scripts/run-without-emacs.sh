#!/bin/bash
set -euo pipefail

# Configuration
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
EXAMPLES_DIR="${REPO_ROOT}/examples"
EMACS_INIT="${REPO_ROOT}/.emacs.d/init.el"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Create temporary Elisp file for executing org files
TMP_ELISP=$(mktemp)
trap 'rm -f $TMP_ELISP' EXIT

cat > "$TMP_ELISP" << 'EOF'
;; Load the init file if it exists
(when (file-exists-p "~/.emacs.d/init.el")
  (load-file "~/.emacs.d/init.el"))

(require 'org)
(require 'ob-shell)
(require 'ob-python)

;; Don't ask for confirmation when executing code blocks
(setq org-confirm-babel-evaluate nil)

;; Function to execute all source blocks in a file
(defun execute-org-file (file)
  (with-current-buffer (find-file-noselect file)
    (org-babel-execute-buffer)
    (save-buffer)))

;; Process each org file provided as command line argument
(dolist (file command-line-args-left)
  (when (file-exists-p file)
    (message "Processing %s..." file)
    (execute-org-file file)))
EOF

# Function to run a single org file
run_org_file() {
    local file=$1
    echo -e "${BLUE}=== Processing ${file} ===${NC}"
    
    # Run Emacs in batch mode
    if emacs --batch \
        --eval "(setq debug-on-error t)" \
        -l "$TMP_ELISP" \
        "$file" 2>&1 | tee /dev/stderr | grep -q "Error"; then
        echo -e "${RED}Failed to process ${file}${NC}"
        return 1
    else
        echo -e "${GREEN}Successfully processed ${file}${NC}"
        return 0
    fi
}

# Function to check prerequisites
check_prereqs() {
    if ! command -v emacs >/dev/null; then
        echo -e "${RED}Error: Emacs is not installed${NC}"
        echo "Please install Emacs to run these examples"
        exit 1
    fi
}

# Main execution
main() {
    check_prereqs
    
    local failed_files=()
    
    if [ $# -eq 0 ]; then
        # No files specified, process all .org files in examples directory
        echo -e "${BLUE}Processing all org files in ${EXAMPLES_DIR}${NC}"
        while IFS= read -r -d '' file; do
            if ! run_org_file "$file"; then
                failed_files+=("$file")
            fi
        done < <(find "$EXAMPLES_DIR" -name "*.org" -print0)
    else
        # Process specified files
        for file in "$@"; do
            if ! run_org_file "$file"; then
                failed_files+=("$file")
            fi
        done
    fi
    
    # Report results
    echo -e "\n${BLUE}=== Execution Summary ===${NC}"
    if [ ${#failed_files[@]} -eq 0 ]; then
        echo -e "${GREEN}All files processed successfully!${NC}"
    else
        echo -e "${RED}The following files had errors:${NC}"
        printf '%s\n' "${failed_files[@]}"
        exit 1
    fi
}

# Show help if requested
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    cat << EOF
Usage: $0 [file1.org file2.org ...]

Run org-mode example files through Emacs in batch mode.
If no files are specified, processes all .org files in examples directory.

Options:
  -h, --help    Show this help message
EOF
    exit 0
fi

main "$@"
