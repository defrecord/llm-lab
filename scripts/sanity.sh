#!/bin/bash

# Run comprehensive sanity checks with multi-model analysis
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SANITY_DIR="data/sanity"

# Function to run and log a make target
run_target() {
    local target=$1
    echo -e "\n${CYAN}Testing ${target}...${NC}"
    make $target 2>&1 | tee "${SANITY_DIR}/${target}.log"
}

echo "Running sanity checks..."

# Check for required tools
echo "Checking required tools..."
command -v uv >/dev/null 2>&1 || { echo "uv not found"; exit 1; }
command -v llm >/dev/null 2>&1 || { echo "llm not found"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl not found"; exit 1; }

# Check virtual environment
echo "Checking virtual environment..."
[ -d ".venv" ] || { echo ".venv not found"; exit 1; }

# Check configuration
echo "Checking configuration..."
[ -f "config/model.conf" ] || { echo "config/model.conf not found"; exit 1; }

# Check for required directories
echo "Checking required directories..."
required_dirs=(
    "data/agents"
    "data/memory"
    "data/dialogue"
    "data/reflection"
    "data/summary"
    "data/embeddings"
    "data/spider"
)

for dir in "${required_dirs[@]}"; do
    [ -d "$dir" ] || { echo "$dir not found"; exit 1; }
done

# Check LLM configuration
echo "Checking LLM configuration..."
source config/model.conf
llm models get "$LLM_MODEL" >/dev/null 2>&1 || { echo "LLM model $LLM_MODEL not found"; exit 1; }

# Create sanity directory
mkdir -p "${SANITY_DIR}"

# Run make targets and log outputs
run_target "init"
run_target "check"
run_target "check-set"
run_target "tangle"
run_target "run"

# Pre-analyze logs with Ollama
echo -e "\n${CYAN}Pre-analyzing logs with Ollama...${NC}"
for log in "${SANITY_DIR}"/*.log; do
    echo -e "\nPre-analyzing ${log} with llama2..."
    llm -m ollama/llama2 "Review this make target output and identify key issues and patterns. Focus on errors, warnings, and potential improvements:" "${log}" 2>&1 | tee "${log}.pre_analysis"
done

# Perform detailed analysis with Claude
echo -e "\n${CYAN}Performing detailed analysis with Anthropic Claude...${NC}"
for log in "${SANITY_DIR}"/*.log; do
    echo -e "\nAnalyzing ${log}..."
    llm -m anthropic "Review the make target output and pre-analysis below. Provide specific, actionable recommendations for improving the Makefile target and related configuration. Focus on:
1. Error handling
2. Dependencies
3. Performance
4. User feedback
5. Resource management

Make Target Output:
$(cat ${log})

Llama2 Pre-analysis:
$(cat ${log}.pre_analysis)" 2>&1 | tee "${log}.analysis"
done

echo -e "\n${GREEN}✓${NC} Sanity check complete. See ${SANITY_DIR}/*.log.analysis for full recommendations"