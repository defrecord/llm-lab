#!/bin/bash
set -euo pipefail

# Configuration
BASE_URL="https://simonwillison.net/tags/llm/"
OUTPUT_DIR="data/spider/simonwillison.net"
PAGES_TO_FETCH=5  # Adjust as needed

# Using llama3.2 by default for consistent, efficient processing
# Override with --model if needed for specific analysis tasks
MODEL="llama3.2"  # Default model

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --pages)
            PAGES_TO_FETCH="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--pages NUM] [--model MODEL_NAME]"
            echo "Default pages: 5"
            echo "Default model: llama3.2"
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
        # Also extract code blocks that might contain llm commands
        awk '/```/{p=!p}p' "$output_file" | grep "llm" || true
    } > "${OUTPUT_DIR}/commands_page_${page_num}.txt"
}

# Function to extract commands from our examples
extract_examples() {
    local examples_dir="examples"
    local examples_file="${OUTPUT_DIR}/our_examples.md"
    
    echo "Extracting commands from our examples..."
    {
        echo "# Our Example Commands"
        echo
        echo "## By File:"
        echo
        for file in "$examples_dir"/*.org; do
            echo "### $(basename "$file")"
            echo
            echo "\`\`\`"
            grep -h "llm" "$file" | grep -v "^#" || true
            echo "\`\`\`"
            echo
        done
    } > "$examples_file"
}

# Function to analyze LLM commands and compare with our examples
analyze_commands() {
    local analysis_file="${OUTPUT_DIR}/command_comparison.md"
    
    echo "Analyzing commands and comparing with our examples..."
    {
        echo "# LLM Command Analysis and Comparison"
        echo
        echo "## Simon's Blog Commands"
        echo
        cat "${OUTPUT_DIR}"/commands_page_*.txt | sort -u
        
        echo
        echo "## Our Example Commands"
        echo
        cat "${OUTPUT_DIR}/our_examples.md"
        
        echo
        echo "## Comparison Analysis"
        echo
        
        # Generate comparison using LLM
        {
            echo "Blog Commands:"
            cat "${OUTPUT_DIR}"/commands_page_*.txt
            echo
            echo "Our Examples:"
            cat "${OUTPUT_DIR}/our_examples.md"
        } | llm -m "$MODEL" "Compare these two sets of LLM commands and provide analysis:

1. Coverage Analysis
   - What commands are well-covered in our examples?
   - What commands are missing?
   - What unique approaches do we have?

2. Usage Patterns
   - Common patterns in blog posts
   - Common patterns in our examples
   - Differences in approach

3. Recommendations
   - Suggested new examples to add
   - Improvements to existing examples
   - Advanced features to showcase

Format as markdown with sections and bullet points."

    } > "$analysis_file"
}

# Function to generate feature matrix
generate_matrix() {
    local matrix_file="${OUTPUT_DIR}/feature_matrix.md"
    
    echo "Generating feature comparison matrix..."
    {
        echo "# LLM Feature Coverage Matrix"
        echo
        echo "| Feature | Blog Posts | Our Examples | Notes |"
        echo "|---------|------------|--------------|-------|"
        
        # Get unique features from both sources
        {
            cat "${OUTPUT_DIR}"/commands_page_*.txt
            grep -h "llm" examples/*.org
        } | grep -o -- "--[a-zA-Z0-9-]*" | sort -u | while read -r feature; do
            blog_count=$(grep -c -- "$feature" "${OUTPUT_DIR}"/commands_page_*.txt || true)
            example_count=$(grep -c -- "$feature" examples/*.org || true)
            echo "| $feature | $blog_count | $example_count | |"
        done
        
    } > "$matrix_file"
}

# Main execution
echo "Starting LLM post analysis using model: $MODEL..."
if [ "$MODEL" = "llama3.2" ]; then
    echo "Using default model llama3.2 for assessments..."
fi

# Fetch blog pages
for page in $(seq 1 $PAGES_TO_FETCH); do
    fetch_page "$page"
done

# Extract our examples
extract_examples

# Analyze and compare commands
analyze_commands

# Generate feature matrix
generate_matrix

echo "Analysis complete! Files available in ${OUTPUT_DIR}:"
echo "- command_comparison.md: Detailed analysis and recommendations"
echo "- feature_matrix.md: Feature coverage comparison"
echo "- our_examples.md: Extracted examples from our codebase"
echo "- page_*.md: Raw blog post content"
echo "- commands_page_*.txt: Extracted commands from blog posts"

# Generate executive summary
echo "Generating executive summary..."
{
    echo "# Executive Summary"
    echo
    cat "${OUTPUT_DIR}/command_comparison.md"
    echo
    echo "## Feature Coverage"
    echo
    cat "${OUTPUT_DIR}/feature_matrix.md"
} | llm -m "$MODEL" "Create an executive summary of our LLM command coverage compared to Simon Willison's blog posts.
Focus on:
1. Overall coverage assessment
2. Key gaps to address
3. Top 3 priorities for improvement
Format as a brief markdown document with bullet points."