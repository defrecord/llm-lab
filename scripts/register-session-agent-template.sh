#!/usr/bin/env bash
# Configuration
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROMPTS_DIR="${REPO_ROOT}/prompts"
SESSION_PROMPT="${PROMPTS_DIR}/session-agent.md"

# Debug flag
DEBUG=0

# Help message
usage() {
    cat << EOF
Usage: $0 [--debug]
Register session agent template using llm command.
By default uses llm session with llama3.2 model.
Options:
    --debug     Enable debug logging
    --manual    Use manual YAML template creation instead of llm session
    -h, --help  Show this help message
EOF
    exit 1
}

# Parse arguments
MANUAL_MODE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG=1
            shift
            ;;
        -h|--help)
            usage
            shift
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
    debug_log "Current LLM Templates:"
    llm templates list | head 
    llm logs on
    llm logs status 
}

validate_template() {
    debug_log "Active Templates: $(llm templates list | grep -c '^')"
    
    # Run basic calculation test
    echo "2 + 2" | llm -t session-agent -c 
    
    # Get Scheme version
    echo "Scheme version of above calculation" | llm -t session-agent -c -x
    
    # Create data directory and generate shell script
    mkdir -p data
    echo "Shell script allowing calc from cli" | llm -t session-agent -c -x | tee data/validate_template_calc.sh
    
    # Get a code review of the generated shell script
    cat data/validate_template_calc.sh | llm -t session-agent -c "Code review this shell script: "
    llm logs --json -n 0  | jq -r '.[]|.model' | llm -t session-agent -c "Summarize the models used"
}

# Function to register template manually (legacy method)
register_template() {
    local template_dir="${REPO_ROOT}/templates"
    local template_file="${template_dir}/session-agent.yaml"
    
    debug_log "Template directory: $template_dir"
    debug_log "Template file: $template_file"
    
    echo "Registering session agent template manually..."
    
    # Show status before registration
    debug_log "Status before registration:"
    show_llm_status
    
    # Create template directory if it doesn't exist
    mkdir -p "$template_dir"
    debug_log "Created/verified template directory"
    
    # Create template file
    cat > "$template_file" << EOL
name: session-agent
model: llama3.2
temperature: 0.7
system: |
$(cat "$SESSION_PROMPT" | sed 's/^/  /')
EOL
    debug_log "Created template file"

    # Register template with llm
    debug_log "Registering template with llm..."
    llm -m llama3.2 -s "$(cat $template_file)" --save session-agent
    
    # Show status after registration
    debug_log "Status after registration:"
    show_llm_status
}

register_template
echo "Session agent template registration complete!"

# Verify registration
echo -e "\nVerifying template registration..."
llm templates list | grep "session-agent" || echo "Warning: Template verification failed"

# Final debug status
if [ $DEBUG -eq 1 ]; then
    debug_log "Final template status:"
    show_llm_status
    validate_template
fi

echo "Use
  llm chat -t session-agent -c
to continue the conversation about the calculator.
Example Chat:
  Summarize what we did previously and then show a Python calculator with the example test but using named ops like add sub mod div etc

"
