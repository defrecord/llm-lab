#!/usr/bin/env bash

# Configuration
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROMPTS_DIR="${REPO_ROOT}/prompts"
SESSION_PROMPT="${PROMPTS_DIR}/session-agent.md"

# Help message
usage() {
    cat << EOF
Usage: $0 [--manual]

Register session agent template using llm command.
By default uses llm session with llama3.2 model.

Options:
    --manual    Use manual YAML template creation instead of llm session
    -h, --help  Show this help message
EOF
    exit 1
}

# Parse arguments
MANUAL_MODE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --manual)
            MANUAL_MODE=1
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

# Function to register template using llm session
register_template_llm() {
    if [ ! -f "$SESSION_PROMPT" ]; then
        echo "Error: Session prompt file not found at $SESSION_PROMPT"
        exit 1
    }

    echo "Registering session agent template using llm session..."
    llm session \
        --system "$(cat $SESSION_PROMPT)" \
        --name session-agent \
        --model llama3.2
}

# Function to register template manually (legacy method)
register_template_manual() {
    local template_dir="${REPO_ROOT}/templates"
    local template_file="${template_dir}/session-agent.yaml"
    
    echo "Registering session agent template manually..."
    
    # Create template directory if it doesn't exist
    mkdir -p "$template_dir"
    
    # Create template file
    cat > "$template_file" << EOL
name: session-agent
model: llama3.2
temperature: 0.7
system: |
$(cat "$SESSION_PROMPT" | sed 's/^/  /')
EOL

    # Register template with llm
    llm --system "$(cat $template_file)" --save session-agent
}

# Main execution
if [ $MANUAL_MODE -eq 1 ]; then
    register_template_manual
else
    register_template_llm
fi

echo "Session agent template registration complete!"

# Verify registration
echo -e "\nVerifying template registration..."
llm templates list | grep "session-agent" || echo "Warning: Template verification failed"