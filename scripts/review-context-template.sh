#!/usr/bin/env bash

# Define the output directory
OUTPUT_DIR="prompts"
mkdir -p "$OUTPUT_DIR"

# Create context review template
declare -A context_review=(
    ["system-context"]="Review the system context, including:
- Operating environment
- Available tools and functions
- System capabilities
- Important constraints"
    ["conversation-context"]="Analyze the conversation context:
- User intent and goals
- Previous interactions
- Established patterns
- Specific requirements mentioned"
    ["template-context"]="Examine the template context:
- Template structure and format
- Required fields and parameters
- Optional elements
- Dependencies and relationships"
    ["adaptation-guidelines"]="Consider context adaptation:
- How to modify templates based on context
- When to apply different template variations
- Context-specific customizations
- Template combination strategies"
)

# Save the context review template
CONTEXT_FILE="$OUTPUT_DIR/context_review_template.txt"
echo "### Context Review Template ###" > "$CONTEXT_FILE"

for section in "${!context_review[@]}"; do
    echo -e "\n**${section^}:**" >> "$CONTEXT_FILE"
    echo -e "${context_review[$section]}" >> "$CONTEXT_FILE"
done

echo "Context review template saved to $CONTEXT_FILE"

# Initialize context with current state
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REVIEW_FILE="context_analysis_${TIMESTAMP}.md"
echo "# Context Analysis - ${TIMESTAMP}" > "$REVIEW_FILE"

# Step 1: Initialize context with system state
files-to-prompt -c . | llm -m llama3.2 -c | tee -a "$REVIEW_FILE"

# Step 2: Review system context
echo "## System Context Analysis" >> "$REVIEW_FILE"
llm -c -t system "Analyze the current system state and available capabilities." | tee -a "$REVIEW_FILE"

# Step 3: Review conversation context
echo "## Conversation Context" >> "$REVIEW_FILE"
llm -c -t memory "Review the conversation history and identify key patterns and requirements." | tee -a "$REVIEW_FILE"

# Step 4: Analyze template usage
echo "## Template Analysis" >> "$REVIEW_FILE"
llm -c -t memory "Evaluate how templates are being used and their effectiveness." | tee -a "$REVIEW_FILE"

# Step 5: Generate recommendations
echo "## Context-Based Recommendations" >> "$REVIEW_FILE"
llm -c -t memory "Provide recommendations for template improvements based on the context analysis." | tee -a "$REVIEW_FILE"

# Step 6: Document adaptations
echo "## Template Adaptations" >> "$REVIEW_FILE"
llm -c -t memory "Document required template adaptations based on context requirements." | tee -a "$REVIEW_FILE"

echo "Context review completed and saved to $REVIEW_FILE"

# Sample usage:
# Step 1: Review current context
# ./review_context_template.sh
#
# Step 2: Apply context-specific template
# llm -c -t <template> "Your prompt here" | tee -a "$REVIEW_FILE"