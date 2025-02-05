#!/bin/bash

# Verify project setup using uv
# Checks Python, uv, virtual environment, and core dependencies

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Running Setup Verification..."

# Check Python
python3 --version >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Python installed"
else
    echo -e "${RED}✗${NC} Python not found"
    exit 1
fi

# Check uv
uv --version >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} uv installed"
else
    echo -e "${RED}✗${NC} uv not found"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} uv installed successfully"
    else
        echo -e "${RED}✗${NC} uv installation failed"
        exit 1
    fi
fi

# Check virtual environment
VENV_DIR=".venv"
if [ -d "$VENV_DIR" ]; then
    echo -e "${GREEN}✓${NC} Virtual environment exists"
else
    echo -e "${RED}✗${NC} Virtual environment missing"
    uv venv
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Virtual environment created"
    else
        echo -e "${RED}✗${NC} Virtual environment creation failed"
        exit 1
    fi
fi

# Check core dependencies
if [ -f "requirements.txt" ]; then
    . "$VENV_DIR/bin/activate"
    uv pip install -r requirements.txt >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Core dependencies installed"
    else
        echo -e "${RED}✗${NC} Dependency installation failed"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} requirements.txt not found"
    exit 1
fi

# Install dev dependencies if present
if [ -f "dev-requirements.txt" ]; then
    uv pip install -r dev-requirements.txt >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Dev dependencies installed"
    fi
fi

echo "Setup verification complete"
