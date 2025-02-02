#!/usr/bin/env bash

# Define the output directory for templates
TEMPLATE_DIR="/home/computeruse/.config/io.datasette.llm/templates"
PROMPT_DIR="$(dirname "$(dirname "$0")")/prompts"

# Ensure template directory exists
mkdir -p "$TEMPLATE_DIR"

# Function to strip markdown tags and format for YAML
format_markdown_to_yaml() {
    local input_file="$1"
    {
        echo "system: |"
        # Process the markdown:
        # 1. Remove code blocks but preserve their content
        # 2. Convert headers to bold text
        # 3. Preserve line breaks but handle indentation
        # 4. Escape special characters
        sed 's/^```.*$//' "$input_file" | \
        sed 's/^#\+[[:space:]]*\(.*\)/\1/' | \
        sed 's/^/  /' | \
        sed 's/"/\\"/g'
    }
}

# Create session agent template
create_session_template() {
    local template_file="$TEMPLATE_DIR/session-agent.yaml"
    local prompt_file="$PROMPT_DIR/session-agent.md"
    
    echo "Creating session agent template..."
    if [ ! -f "$prompt_file" ]; then
        echo "Error: Session agent prompt file not found at $prompt_file"
        exit 1
    fi
    
    # Format the content and save as YAML
    format_markdown_to_yaml "$prompt_file" > "$template_file"
    echo "Created template: $template_file"
    
    # Verify the template
    echo "Verifying template..."
    if python3 -c "import yaml; yaml.safe_load(open('$template_file'))"; then
        echo "Template validation successful"
    else
        echo "Error: Template validation failed"
        exit 1
    fi
}

# Install Python YAML package if needed
if ! python3 -c "import yaml" 2>/dev/null; then
    echo "Installing PyYAML..."
    pip install PyYAML
fi

# Create the template
create_session_template

# Show template list
echo -e "\nAvailable templates:"
llm templates list