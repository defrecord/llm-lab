#!/usr/bin/env bash

# Enable error handling
set -euo pipefail

# Source configuration if available
if [ -f config/model.conf ]; then
    source config/model.conf
fi

ANALYSIS_DIR="/tmp/guide-analysis-$(date +%Y%m%d-%H%M%S)"
RAW_DIR="examples/.guides"
PROCESSED_DIR="examples/.guides/processed"
ANALYSIS_RESULTS="$ANALYSIS_DIR/results"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$ANALYSIS_DIR/analysis.log"
}

# Initialize directories
mkdir -p "$ANALYSIS_DIR" "$ANALYSIS_RESULTS"

# Function to analyze a single response
analyze_response() {
    local guide_path="$1"
    local name=$(basename "$(dirname "$guide_path")")
    local analysis_file="$ANALYSIS_RESULTS/${name}_analysis.md"
    
    log "Analyzing response for $name..."
    
    # Save raw response
    cp "$guide_path" "$ANALYSIS_DIR/raw_${name}.txt"
    
    # Extract thinking process
    grep '<think>' "$guide_path" > "$ANALYSIS_DIR/${name}_thinking.txt" || true
    
    # Extract actual content
    grep -v '<think>' "$guide_path" | grep -v '^$' > "$ANALYSIS_DIR/${name}_content.txt"
    
    # Analyze structure
    {
        echo "# Analysis for $name"
        echo
        echo "## Structure Analysis"
        echo "- Lines total: $(wc -l < "$guide_path")"
        echo "- Content lines: $(wc -l < "$ANALYSIS_DIR/${name}_content.txt")"
        echo "- Thinking lines: $(wc -l < "$ANALYSIS_DIR/${name}_thinking.txt")"
        echo
        echo "## Headers Found"
        grep '^#\|^\*' "$ANALYSIS_DIR/${name}_content.txt" || echo "No headers found"
        echo
        echo "## Code Blocks"
        grep -A 1 '```\|#+BEGIN_SRC' "$ANALYSIS_DIR/${name}_content.txt" || echo "No code blocks found"
        echo
        echo "## Thinking Process Summary"
        if [ -s "$ANALYSIS_DIR/${name}_thinking.txt" ]; then
            cat "$ANALYSIS_DIR/${name}_thinking.txt"
        else
            echo "No explicit thinking process found"
        fi
        echo
        echo "## Content Quality Checks"
        # Check for proper structure
        if grep -q '^#\|^\*' "$ANALYSIS_DIR/${name}_content.txt"; then
            echo "✓ Has proper headers"
        else
            echo "✗ Missing proper headers"
        fi
        # Check for code examples
        if grep -q '```\|#+BEGIN_SRC' "$ANALYSIS_DIR/${name}_content.txt"; then
            echo "✓ Contains code examples"
        else
            echo "✗ Missing code examples"
        fi
        # Check for installation section
        if grep -qi 'installation\|setup' "$ANALYSIS_DIR/${name}_content.txt"; then
            echo "✓ Has installation/setup section"
        else
            echo "✗ Missing installation/setup section"
        fi
        # Check for examples
        if grep -qi 'example\|usage' "$ANALYSIS_DIR/${name}_content.txt"; then
            echo "✓ Contains examples"
        else
            echo "✗ Missing examples"
        fi
    } > "$analysis_file"
}

# Function to generate summary report
generate_summary() {
    local summary_file="$ANALYSIS_DIR/summary.md"
    
    {
        echo "# Guide Analysis Summary"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "## Overview"
        echo "- Total guides analyzed: $(find "$RAW_DIR" -name "README.org" -type f | wc -l)"
        echo "- Guides with content: $(find "$ANALYSIS_DIR" -name "*_content.txt" -type f -not -empty | wc -l)"
        echo "- Guides with thinking process: $(find "$ANALYSIS_DIR" -name "*_thinking.txt" -type f -not -empty | wc -l)"
        echo
        echo "## Quality Metrics"
        echo
        for f in "$ANALYSIS_RESULTS"/*_analysis.md; do
            if [ -f "$f" ]; then
                name=$(basename "$f" _analysis.md)
                echo "### $name"
                grep '^[✓✗]' "$f" || echo "No quality checks found"
                echo
            fi
        done
        
        echo "## Recommendations"
        echo "Based on the analysis, the following improvements are recommended:"
        echo
        # Generate recommendations based on analysis
        for f in "$ANALYSIS_RESULTS"/*_analysis.md; do
            if [ -f "$f" ]; then
                name=$(basename "$f" _analysis.md)
                echo "### $name"
                if grep -q '✗' "$f"; then
                    echo "Needs improvement in:"
                    grep '^✗' "$f" | sed 's/✗ /- /'
                else
                    echo "Meets all quality criteria"
                fi
                echo
            fi
        done
    } > "$summary_file"
}

main() {
    log "Starting guide analysis"
    
    # Analyze each guide
    while IFS= read -r -d '' guide; do
        analyze_response "$guide"
    done < <(find "$RAW_DIR" -name "README.org" -type f -print0)
    
    # Generate summary
    generate_summary
    
    log "Analysis complete. Results in $ANALYSIS_DIR"
    echo "Analysis results available in: $ANALYSIS_DIR"
    echo "Summary file: $ANALYSIS_DIR/summary.md"
}

main "$@"