#!/bin/bash

# Configuration
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ANALYSIS_DIR="${REPO_ROOT}/analysis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${ANALYSIS_DIR}/repo_analysis_${TIMESTAMP}.md"

# Create analysis directory
mkdir -p "${ANALYSIS_DIR}"

# Function to analyze repository structure
analyze_repo_structure() {
    echo "## Repository Structure"
    echo '```'
    # Exclude common directories and files
    tree -a -I '.git|.venv|__pycache__|*.pyc|*.pyo|*.pyd|.DS_Store|node_modules' "${REPO_ROOT}"
    echo '```'
}

# Function to analyze script features
analyze_scripts() {
    echo "## Script Analysis"
    echo "### Template Scripts"
    for script in "${REPO_ROOT}"/scripts/*template*.sh; do
        if [ -f "$script" ]; then
            echo -e "\n#### $(basename "$script")"
            echo '```bash'
            grep -A 5 "^# Features:" "$script" 2>/dev/null || echo "No explicit features documented"
            echo '```'
            
            # Extract function names
            echo -e "\nFunctions:"
            echo '```'
            grep "^function" "$script" 2>/dev/null | sed 's/function \([^ (]*\).*/\1/' || echo "No functions found"
            echo '```'
        fi
    done
}

# Function to analyze template usage
analyze_templates() {
    echo "## Template Analysis"
    echo "### Existing Templates"
    for template in "${REPO_ROOT}"/prompts/*.{txt,md}; do
        if [ -f "$template" ]; then
            echo -e "\n#### $(basename "$template")"
            echo '```'
            head -n 10 "$template" 2>/dev/null || echo "Empty or unreadable template"
            echo '```'
        fi
    done
}

# Function to analyze code patterns
analyze_code_patterns() {
    echo "## Code Pattern Analysis"
    echo "### Common Patterns"
    echo '```'
    find "${REPO_ROOT}" -type f -name "*.sh" -o -name "*.py" | while read -r file; do
        if [ -f "$file" ]; then
            echo "File: $(basename "$file")"
            # Look for template registration patterns
            grep -l "llm.*--system" "$file" 2>/dev/null && echo "- Contains LLM system prompts"
            # Look for template usage
            grep -l "llm.*-t" "$file" 2>/dev/null && echo "- Uses templates"
        fi
    done
    echo '```'
}

# Function to generate SIN framework analysis
generate_sin_analysis() {
    cat << 'EOF'
## SIN Framework Analysis

### Structure
- How is the codebase organized?
- What patterns emerge in the implementation?
- What architectural decisions are visible?

### Interpretation
- How are templates being used?
- What is the flow of data between components?
- How are system prompts structured?

### Naming
- Are naming conventions consistent?
- Do script names reflect their purpose?
- Are templates named meaningfully?

### Recommendations

#### High Priority
1. Template Management
   - [ ] Standardize template registration
   - [ ] Implement template validation
   - [ ] Add version control for templates

2. Documentation
   - [ ] Add inline documentation
   - [ ] Create usage examples
   - [ ] Document template formats

3. Integration
   - [ ] Standardize LLM interfaces
   - [ ] Implement error handling
   - [ ] Add logging

#### Future Improvements
1. [ ] Template version control
2. [ ] Automated testing
3. [ ] Performance monitoring
4. [ ] User documentation
EOF
}

# Generate the full analysis
{
    echo "# Repository Analysis (${TIMESTAMP})"
    echo
    analyze_repo_structure
    echo
    analyze_scripts
    echo
    analyze_templates
    echo
    analyze_code_patterns
    echo
    generate_sin_analysis
} > "${OUTPUT_FILE}"

echo "Analysis complete. Output written to: ${OUTPUT_FILE}"

# Optional: Open the analysis file if a viewer is available
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${OUTPUT_FILE}"
elif command -v open >/dev/null 2>&1; then
    open "${OUTPUT_FILE}"
else
    echo "Please open ${OUTPUT_FILE} manually to view the analysis"
fi