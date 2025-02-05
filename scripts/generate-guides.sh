#!/usr/bin/env bash

# Enable error handling
set -euo pipefail

# Source configuration if available
if [ -f config/model.conf ]; then
    source config/model.conf
fi

# Ensure we're in the virtual environment
if [ -z "${VIRTUAL_ENV:-}" ]; then
    if [ -d .venv ]; then
        source .venv/bin/activate
    else
        echo "Error: Virtual environment not found"
        exit 1
    fi
fi

# Check for required tools
check_dependencies() {
    local missing_deps=()
    
    if ! command -v pandoc >/dev/null 2>&1; then
        missing_deps+=("pandoc")
    fi
    
    if ! command -v uv >/dev/null 2>&1; then
        missing_deps+=("uv")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies and try again"
        exit 1
    fi
}

# Set up logging
LOGDIR="/tmp/guide-generation-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGDIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGDIR/generation.log"
}

# Process guides
process_guides() {
    local guides_dir="examples/.guides"
    local processed_dir="$guides_dir/processed"
    mkdir -p "$processed_dir"
    
    log "Converting formats..."
    find "$guides_dir" -name "README.org" -type f | while read -r f; do
        base=$(dirname "$f")
        name=$(basename "$base")
        log "Processing $name..."
        
        # Clean and convert format
        grep -v '<think>' "$f" | grep -v '^$' > "$processed_dir/${name}.md"
        if [ -s "$processed_dir/${name}.md" ]; then
            pandoc -f markdown -t org -o "$processed_dir/${name}.org" "$processed_dir/${name}.md" 2>/dev/null
            log "Successfully processed $name"
        else
            log "Warning: Empty content for $name"
        fi
    done
}

main() {
    log "Starting guide generation process"
    
    # Check dependencies
    check_dependencies
    
    # Generate initial guides
    log "Running guide generator"
    if [ -f scripts/create-examples-guides.sh.fixed ]; then
        ./scripts/create-examples-guides.sh.fixed
    else
        log "Error: Guide generator script not found"
        exit 1
    fi
    
    # Process and convert guides
    process_guides
    
    # Generate final report
    {
        echo "=== Final Generation Report ==="
        echo "Completed at: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "=== Generated Guides ==="
        find examples/.guides/processed -name "*.org" -type f -ls
        echo ""
        echo "=== Log Location ==="
        echo "$LOGDIR"
    } | tee "$LOGDIR/final_report.log"
    
    log "Guide generation process complete"
}

main "$@"