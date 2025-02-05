#!/bin/bash

# Initialize project environment and structure
# Sets up required directories and installs dependencies

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Initializing project environment..."

# Create required directories
for dir in data/sanity data/output data/sin data/images; do
    mkdir -p "$dir"
    echo -e "${GREEN}✓${NC} Created $dir"
done

# Install core dependencies
echo "Installing core dependencies..."
if ! uv add fetch-github-issues files-to-prompt llm sqlite-utils strip-tags ttok; then
    echo -e "${RED}✗${NC} Failed to install core dependencies"
    exit 1
fi

# Install LLM providers
echo "Installing LLM providers..."
if ! llm install llm-anthropic llm-cluster llm-ollama llm-claude llm-bedrock llm-gemini; then
    echo -e "${RED}✗${NC} Failed to install LLM providers"
    exit 1
fi

echo -e "${GREEN}✓${NC} Project initialization complete"
