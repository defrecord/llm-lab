#!/bin/bash

# Run all sanity checks for the project
set -e

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

echo "All sanity checks passed!"