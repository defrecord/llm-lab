#!/usr/bin/env bash

# Define the output directory
OUTPUT_DIR="prompts"
mkdir -p "$OUTPUT_DIR"

# Define the Structured Insight Navigator (SIN) template
declare -A sin_template=(
    ["phase-1-input-and-analysis"]="Welcome to the Structured Insight Navigator (SIN)! Please provide the article, text, or note you'd like to analyze. Once I review the content, I will recommend the most suitable process or framework to summarize, assess, estimate, or evaluate it. If you have a specific goal in mind (e.g., summarizing, risk assessment, problem-solving), feel free to mention it to guide my recommendation."
    ["phase-2-recommendation-and-alternatives"]="Based on the content you provided, I recommend using the [Recommended Process] framework. Here’s why it’s a good fit:\n\n[Brief explanation of why the process aligns with the content and your goal].\n\nIf you’d prefer a different approach, here are other suitable processes you might consider:\n\n[Alternative Process 1]: [Brief description of when to use it].\n[Alternative Process 2]: [Brief description of when to use it].\n[Alternative Process 3]: [Brief description of when to use it].\n\nLet me know which process you’d like to use, and I’ll guide you through it step-by-step!"
    ["key-frameworks"]="Here are the key frameworks SIN uses for recommendations:\n\n- Summarization & Problem-Solving: PQRST, TOP5, KWL, PSBDARP.\n- Risk Assessment & Estimation: FMEA, PERT, RAID, 5x5 Risk Matrix, STEEPLE.\n- Strategic Analysis: SWOT, MoSCoW."
)

# Save the SIN template to a file
SIN_FILE="$OUTPUT_DIR/sin_template.txt"
echo "### Structured Insight Navigator (SIN) Template ###" > "$SIN_FILE"

for element in "${!sin_template[@]}"; do
    echo -e "\n**${element^}:**" >> "$SIN_FILE"
    echo -e "${sin_template[$element]}" >> "$SIN_FILE"
done

echo "SIN template saved to $SIN_FILE"

# Define the primary elements for other templates
declare -A elements=(
    ["background-information"]="Essential data and objectives pertinent to the experimental setup."
    ["dialogue-history"]="Tracks participant dialogues."
    ["violation-log"]="Tracks instances of detection by the supervisor."
    ["regulations"]="Rules and constraints formulated by the Reflection and Summary modules."
    ["guidance"]="Assists agents in stealthily disseminating information."
    ["plan"]="A strategy formulated by the Reflection and Summary modules."
    ["instructions"]="Specific tasks for the LLM within each module."
)

# Define the modules
modules=("memory" "dialogue" "reflection" "summary")

# Function to generate a prompt for a module
generate_prompt() {
    local module=$1
    local prompt_file="$OUTPUT_DIR/${module}-prompt.txt"

    echo "Generating prompt for $module module..."
    echo "### ${module^} Module Prompt ###" > "$prompt_file"

    for element in "${!elements[@]}"; do
        echo -e "\n**${element^}:**" >> "$prompt_file"
        echo "${elements[$element]}" >> "$prompt_file"
    done

    echo "Prompt saved to $prompt_file"
}

# Generate prompts for each module
for module in "${modules[@]}"; do
    generate_prompt "$module"
done

echo "All prompts have been generated and saved in the '$OUTPUT_DIR' directory."

# Initialize context with the codebase and create a markdown file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REVIEW_FILE="codebase_review_${TIMESTAMP}.md"
echo "# Codebase Review - ${TIMESTAMP}" > "$REVIEW_FILE"

# Step 1: Initialize context with the codebase
find . -type f -name "*.sh" -o -name "*.py" | files-to-prompt > "$REVIEW_FILE"

# Step 2: Add SIN Analysis section
echo -e "\n## Structured Insight Navigator (SIN) Analysis" >> "$REVIEW_FILE"
echo "Using base SIN template for analysis..." >> "$REVIEW_FILE"
cat "$OUTPUT_DIR/sin_template.txt" >> "$REVIEW_FILE"

# Step 3: Add RAID Analysis section
echo -e "\n## RAID Analysis" >> "$REVIEW_FILE"
echo "Risk Assessment:" >> "$REVIEW_FILE"
echo "1. Identifying potential risks" >> "$REVIEW_FILE"
echo "2. Analyzing assumptions" >> "$REVIEW_FILE"
echo "3. Documenting issues" >> "$REVIEW_FILE"
echo "4. Mapping dependencies" >> "$REVIEW_FILE"

# Step 4: Additional analysis sections
echo -e "\n## Project Components" >> "$REVIEW_FILE"
echo "Key Files and Directories:" >> "$REVIEW_FILE"
find . -type f -not -path '*/\.*' | sort >> "$REVIEW_FILE"

echo -e "\n## Documentation Status" >> "$REVIEW_FILE"
echo "Documentation Review:" >> "$REVIEW_FILE"
echo "1. README files" >> "$REVIEW_FILE"
echo "2. Inline documentation" >> "$REVIEW_FILE"
echo "3. API documentation" >> "$REVIEW_FILE"
echo "4. Usage examples" >> "$REVIEW_FILE"

echo -e "\n## Dependencies" >> "$REVIEW_FILE"
echo "External Dependencies:" >> "$REVIEW_FILE"
if [ -f "requirements.txt" ]; then
    echo "Python dependencies:" >> "$REVIEW_FILE"
    cat requirements.txt >> "$REVIEW_FILE"
fi
if [ -f "package.json" ]; then
    echo "Node.js dependencies:" >> "$REVIEW_FILE"
    cat package.json >> "$REVIEW_FILE"
fi

echo -e "\n## TODO Items" >> "$REVIEW_FILE"
echo "TODO and FIXME items:" >> "$REVIEW_FILE"
find . -type f -not -path '*/\.*' -exec grep -l -i "TODO\|FIXME" {} \; >> "$REVIEW_FILE"

echo "Review completed and saved to $REVIEW_FILE"

# Create a list of all templates
template_list="$OUTPUT_DIR/template-list.txt"
echo "### Available Templates ###" > "$template_list"

echo -e "\nSIN Templates:" >> "$template_list"
# Add base SIN template
echo "- sin_template.txt" >> "$template_list"

# Add module templates
for module in "${modules[@]}"; do
    echo "- ${module}-prompt.txt" >> "$template_list"
done

# Add additional SIN templates
declare -A additional_sin_templates=(
    ["analysis"]="Welcome to SIN Analysis:
1. Input Review
2. Framework Selection
3. Systematic Analysis
4. Insight Generation
5. Recommendations"

    ["estimation"]="SIN Estimation Process:
1. Scope Definition
2. Component Breakdown
3. Effort Estimation
4. Risk Assessment
5. Timeline Creation"

    ["evaluation"]="SIN Evaluation Framework:
1. Criteria Definition
2. Evidence Collection
3. Performance Analysis
4. Scoring System
5. Recommendations"

    ["planning"]="SIN Planning Template:
1. Goal Setting
2. Resource Analysis
3. Task Breakdown
4. Timeline Development
5. Risk Management"
)

# Create additional SIN templates and add them to llm
for template in "${!additional_sin_templates[@]}"; do
    template_file="$OUTPUT_DIR/sin-${template}-template.txt"
    template_name="sin-${template}"
    
    # Create template file
    echo "### SIN ${template^} Template ###" > "$template_file"
    echo -e "${additional_sin_templates[$template]}" >> "$template_file"
    echo "- ${template_name}-template.txt" >> "$template_list"
    
    # Add template to llm
    llm_template_file="/home/computeruse/.config/io.datasette.llm/templates/${template_name}.yaml"
    # Create proper YAML format
    {
        echo "system: |"
        cat "$template_file" | sed 's/^/  /'
    } > "$llm_template_file"
    echo "Created and registered template: ${template_name}"
done

# Add base SIN template to llm
{
    echo "system: |"
    cat "$SIN_FILE" | sed 's/^/  /'
} > "/home/computeruse/.config/io.datasette.llm/templates/sin.yaml"
echo "Added base SIN template to llm"

# Add module templates to llm if not already present
for module in "${modules[@]}"; do
    template_file="$OUTPUT_DIR/${module}-prompt.txt"
    llm_template_file="/home/computeruse/.config/io.datasette.llm/templates/${module}.yaml"
    {
        echo "system: |"
        cat "$template_file" | sed 's/^/  /'
    } > "$llm_template_file"
    echo "Added ${module} template to llm"
done

echo "Template list created at: $template_list"
echo "All templates have been added to llm. Run 'llm templates' to see them."