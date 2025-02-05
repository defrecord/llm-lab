#!/bin/bash

# Check LLM tools availability
# Verifies: llm, files-to-prompt, ttok, and stip tags

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

VENV_DIR=".venv"
REQUIRED_CMDS=(llm files-to-prompt ttok strip-tags)

echo "Checking core LLM commands..."

# Ensure we're in virtual environment
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo -e "${RED}✗${NC} Virtual environment not found. Run 'make init' first."
    exit 1
fi

# Source virtual environment
source "$VENV_DIR/bin/activate"

# Check each required command
FAILED=0
for cmd in "${REQUIRED_CMDS[@]}"; do
    printf "Checking %-15s" "$cmd..."
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        FAILED=1
    fi
done

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓${NC} All core LLM commands are available"
    exit 0
else
    echo -e "\n${RED}✗${NC} Some required commands are missing. Run 'make init' to install dependencies."
    exit 1
fi
