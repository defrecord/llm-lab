#!/bin/bash

# Configuration
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TEMPLATE_DIR="${REPO_ROOT}/prompts"
OUTPUT_DIR="${REPO_ROOT}/analysis/sin"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Function to register SIN template
register_sin_template() {
    local template_file="${TEMPLATE_DIR}/sin_template.txt"
    
    # Create template if it doesn't exist
    if [ ! -f "$template_file" ]; then
        cat > "$template_file" << 'EOL'
name: sin_framework
model: llama2
temperature: 0.7
system: |
  You are a Structured Insight Navigator (SIN) specialized in:
  1. Structure: Organizing and analyzing codebases
  2. Interpretation: Understanding patterns and relationships
  3. Naming: Evaluating and suggesting consistent naming conventions

  Input: Repository content or code segment
  Output: Structured analysis following:
  
  1. Input Review
     - Repository structure
     - Key components
     - Existing patterns
  
  2. Framework Selection
     - Recommended analysis framework
     - Justification
     - Alternatives
  
  3. Systematic Analysis
     - Using selected framework
     - Evidence-based observations
     - Pattern identification
  
  4. Recommendations
     - High priority items
     - Medium priority items
     - Low priority items
     
  5. Implementation Plan
     - Concrete steps
     - Timeline
     - Dependencies
EOL
    fi

    # Register the template
    llm --system "$(cat $template_file)" --save sin_framework
}

# Function to test template with repository analysis
test_sin_template() {
    local output_file="${OUTPUT_DIR}/sin_analysis_${TIMESTAMP}.md"
    
    # Generate repository structure
    echo "Analyzing repository structure..."
    tree -a -I '.git|.venv|__pycache__|*.pyc|*.pyo|*.pyd|.DS_Store|node_modules' "${REPO_ROOT}" > "${OUTPUT_DIR}/repo_structure.txt"
    
    # Run SIN analysis
    echo "Running SIN analysis..."
    cat "${OUTPUT_DIR}/repo_structure.txt" | llm -t sin_framework > "$output_file"
    
    echo "Analysis complete. Results saved to: $output_file"
    cat "$output_file"
}

# Main execution
echo "=== Testing SIN Template ==="
echo "1. Registering template..."
register_sin_template

echo -e "\n2. Running test analysis..."
test_sin_template