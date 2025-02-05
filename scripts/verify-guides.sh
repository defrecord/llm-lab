#!/usr/bin/env bash

# Enable error handling
set -euo pipefail

# Source configuration if available
if [ -f config/model.conf ]; then
    source config/model.conf
fi

# Verification log directory
LOGDIR="/tmp/guide-verification-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGDIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGDIR/verification.log"
}

# Verify org-mode structure
verify_org_structure() {
    local file="$1"
    local issues=0
    
    # Check for basic org-mode headers
    if ! grep -q "^* " "$file"; then
        log "WARNING: No org-mode headers in $file"
        ((issues++))
    fi
    
    # Check for code blocks
    if ! grep -q "^#+BEGIN_SRC" "$file"; then
        log "WARNING: No code blocks found in $file"
        ((issues++))
    fi
    
    # Check for proper sections
    local required_sections=("Setup" "Configuration" "Examples" "Best Practices")
    for section in "${required_sections[@]}"; do
        if ! grep -qi "^* .*$section" "$file"; then
            log "WARNING: Missing '$section' section in $file"
            ((issues++))
        fi
    done
    
    return $issues
}

# Verify guide content
verify_guide() {
    local file="$1"
    local name=$(basename "$file")
    local issues=0
    
    log "Checking $name..."
    
    # Check file exists and is not empty
    if [ ! -f "$file" ]; then
        log "ERROR: File does not exist: $file"
        return 1
    fi
    
    if [ ! -s "$file" ]; then
        log "ERROR: Empty file: $file"
        return 1
    fi
    
    # Verify org-mode structure
    verify_org_structure "$file"
    issues=$?
    
    # Report status
    if [ $issues -eq 0 ]; then
        log "SUCCESS: $name passes all checks"
    else
        log "NOTICE: $name has $issues warning(s)"
    fi
    
    return $issues
}

main() {
    local processed_dir="examples/.guides/processed"
    local total_issues=0
    local total_files=0
    local failed_files=0
    
    log "Starting guide verification"
    
    # Check processed directory exists
    if [ ! -d "$processed_dir" ]; then
        log "ERROR: Processed guides directory not found: $processed_dir"
        exit 1
    fi
    
    # Verify each guide
    while IFS= read -r -d '' file; do
        ((total_files++))
        verify_guide "$file"
        result=$?
        ((total_issues+=result))
        if [ $result -ne 0 ]; then
            ((failed_files++))
        fi
    done < <(find "$processed_dir" -name "*.org" -type f -print0)
    
    # Generate summary report
    {
        echo "=== Guide Verification Summary ==="
        echo "Completed at: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Total files checked: $total_files"
        echo "Files with issues: $failed_files"
        echo "Total issues found: $total_issues"
        echo ""
        echo "See detailed log at: $LOGDIR/verification.log"
    } | tee "$LOGDIR/summary.log"
    
    # Exit with status based on issues
    if [ $total_issues -gt 0 ]; then
        exit 1
    fi
}

main "$@"