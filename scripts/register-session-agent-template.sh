#!/usr/bin/env bash
set -e  # Exit on error

# Configuration
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROMPTS_DIR="${REPO_ROOT}/prompts"
SESSION_PROMPT="${PROMPTS_DIR}/session-agent.md"
DEBUG=0

# Help message
usage() {
    cat << EOF
Usage: $0 [--debug]
Register session agent template using llm command.
By default uses llm session with llama3.2 model.
Options:
    --debug     Enable debug logging
    -h, --help  Show this help message
EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Debug function
debug_log() {
    if [ $DEBUG -eq 1 ]; then
        echo "[DEBUG] $1"
    fi
}

# Function to show llm status
show_llm_status() {
    if [ $DEBUG -eq 1 ]; then
        echo "Current LLM Templates:"
        llm templates list | head 
        llm logs on
        llm logs status 
    fi
}

validate_template() {
    if [ $DEBUG -eq 1 ]; then
        debug_log "Running validation tests..."
        echo "2 + 2" | llm -t session-agent -c 
        echo "Scheme version of above calculation" | llm -t session-agent -c -x
        mkdir -p data
        echo "Shell script allowing calc from cli" | llm -t session-agent -c -x | tee data/validate_template_calc.sh
        echo "Reviewing generated script..."
        cat data/validate_template_calc.sh | llm -t session-agent -c "Code review this shell script: "
        echo "Analyzing model usage..."
        llm logs --json -n 0 | jq -r '.[]|.model' | llm -t session-agent -c "Summarize the models used"
    fi
}

register_template() {
    local template_dir="${REPO_ROOT}/templates"
    local template_file="${template_dir}/session-agent.yaml"
    
    debug_log "Template directory: $template_dir"
    debug_log "Template file: $template_file"
    
    [ $DEBUG -eq 1 ] && echo "Registering session agent template..."
    
    show_llm_status
    
    mkdir -p "$template_dir"
    debug_log "Created/verified template directory"
    
    cat > "$template_file" << EOL
name: session-agent
model: llama3.2
temperature: 0.7
system: |
$(cat "$SESSION_PROMPT" | sed 's/^/  /')
EOL
    debug_log "Created template file"

    [ $DEBUG -eq 1 ] && echo "Registering with llm..."
    llm -m llama3.2 -s "$(cat $template_file)" --save session-agent > /dev/null 2>&1
    
    show_llm_status
}

# Main execution
register_template

[ $DEBUG -eq 1 ] && echo "Session agent template registration complete!"

# Verify registration quietly
if ! llm templates list | grep -q "session-agent"; then
    echo "Warning: Template verification failed"
    exit 1
fi

[ $DEBUG -eq 1 ] && validate_template

# Always show usage hint
# Final output with easily copyable commands
echo -e "\nReady! You can run:\n"
echo "  llm chat -t session-agent -c "
echo -e "\nExample chat input:\n"
echo "  Summarize what we did previously or assume '2 + 2' and then show a Python calculator with the example test but using named ops like add sub mod div etc"

