#!/bin/bash
set -euo pipefail

# Configuration
BASE_URL="https://simonwillison.net/tags/llm/"
OUTPUT_DIR="data/spider/simonwillison.net"
PAGES_TO_FETCH=5  # Adjust as needed
MODEL="llama3.2"  # Default to llama3.2 for cost efficiency
EXAMPLES_DIR="examples"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --pages)
            PAGES_TO_FETCH="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--model MODEL] [--pages NUM]"
            echo "Default model: llama3.2"
            echo "Default pages: 5"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to fetch and process a page
fetch_page() {
    local page_num=$1
    local output_file="${OUTPUT_DIR}/page_${page_num}.html"
    local parsed_file="${OUTPUT_DIR}/page_${page_num}.md"
    
    echo "Fetching page ${page_num}..."
    
    # Fetch the page
    curl -s "${BASE_URL}?page=${page_num}" > "$output_file"
    
    # Extract content using strip-tags and store as markdown
    strip-tags < "$output_file" > "$parsed_file"
    
    # Extract LLM commands using grep
    echo "Extracting LLM commands from page ${page_num}..."
    {
        echo "# LLM Commands from Page ${page_num}"
        echo
        grep -o '`llm[^`]*`' "$output_file" | sed 's/`//g' || true
    } > "${OUTPUT_DIR}/commands_page_${page_num}.txt"
}

# Function to extract commands from examples
extract_example_commands() {
    local examples_file="${OUTPUT_DIR}/examples_commands.txt"
    
    echo "Extracting commands from examples..."
    {
        echo "# LLM Commands from Examples"
        echo
        find "$EXAMPLES_DIR" -type f -name "*.org" -exec grep -h "llm" {} \; | \
            grep -v "^#" | \
            sort -u
    } > "$examples_file"
}

# Function to analyze LLM commands
analyze_commands() {
    local analysis_file="${OUTPUT_DIR}/command_analysis.md"
    
    echo "Analyzing all extracted commands..."
    {
        echo "# LLM Command Analysis"
        echo
        echo "## All Unique Commands from Simon's Blog"
        echo
        cat "${OUTPUT_DIR}"/commands_page_*.txt | sort -u
        
        echo
        echo "## Commands from Our Examples"
        echo
        cat "${OUTPUT_DIR}/examples_commands.txt"
        
        echo
        echo "## Coverage Analysis"
        echo
        # Use llm to analyze the coverage
        {
            echo "Blog Commands:"
            cat "${OUTPUT_DIR}"/commands_page_*.txt
            echo
            echo "Our Examples:"
            cat "${OUTPUT_DIR}/examples_commands.txt"
        } | llm -m "$MODEL" "Compare these two sets of LLM commands:
1. Identify which core LLM features we cover well in our examples
2. List important features from the blog that we're missing
3. Suggest new examples we should add
Format the response with markdown headers and bullet points."
        
    } > "$analysis_file"
}

# Function to generate comprehensive documentation
generate_docs() {
    local docs_file="${OUTPUT_DIR}/llm_documentation.md"
    
    echo "Generating comprehensive documentation..."
    {
        echo "# LLM Tool Documentation"
        echo
        echo "## Command Reference"
        echo
        llm --help
        
        echo
        echo "## Subcommands"
        echo
        
        # Get all subcommands from help
        for cmd in $(llm --help | grep "^  [a-z]" | awk '{print $1}'); do
            echo "### ${cmd}"
            echo
            echo "\`\`\`"
            llm "$cmd" --help
            echo "\`\`\`"
            echo
        done
        
        echo
        echo "## Example Coverage Matrix"
        echo
        echo "| Command | Covered in Examples | File | Notes |"
        echo "|---------|-------------------|------|-------|"
        
        # Compare available commands with our examples
        for cmd in $(llm --help | grep "^  [a-z]" | awk '{print $1}'); do
            covered=$(find "$EXAMPLES_DIR" -type f -name "*.org" -exec grep -l "llm $cmd" {} \; | head -1)
            if [ -n "$covered" ]; then
                echo "| \`$cmd\` | ✓ | \`${covered#./}\` | |"
            else
                echo "| \`$cmd\` | ✗ | - | Missing example |"
            fi
        done
        
    } > "$docs_file"
}

# Main execution
echo "Starting LLM command coverage analysis..."

# Fetch blog pages
for page in $(seq 1 $PAGES_TO_FETCH); do
    fetch_page "$page"
done

# Extract commands from our examples
extract_example_commands

# Analyze commands and coverage
analyze_commands

# Generate documentation with coverage matrix
generate_docs

echo "Done! Analysis files are in ${OUTPUT_DIR}"

# Generate a summary
echo "Generating summary..."
{
    echo "# Command Coverage Summary"
    echo
    echo "## Current Coverage"
    grep "| \`" "${OUTPUT_DIR}/llm_documentation.md" | grep "✓" | wc -l
    echo " commands covered out of "
    grep "| \`" "${OUTPUT_DIR}/llm_documentation.md" | wc -l
    echo " total commands"
    echo
    echo "## Missing Commands"
    grep "| \`" "${OUTPUT_DIR}/llm_documentation.md" | grep "✗" | sed 's/|.*`\([^`]*\)`.*|/\1/'
} | llm -m "$MODEL" "Create an actionable summary of our LLM command coverage. 
Suggest which missing commands we should prioritize adding examples for.
Format as markdown with bullet points."