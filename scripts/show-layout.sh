#!/bin/bash

# Show project directory structure and descriptions
# Reads .description files for each directory

# Colors for better readability
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color

echo -e "${CYAN}Project Layout:${NC}"
echo -e "${YELLOW}Directory           Description${NC}"
echo "----------------------------------------"

# Find all immediate subdirectories
for dir in */; do
    if [ -f "${dir}.description" ]; then
        # Read description, handle potential special characters
        desc=$(cat "${dir}.description" | tr -d '\n')
        printf "%-20s %s\n" "${dir}" "${desc}"
    else
        printf "%-20s %s\n" "${dir}" "No description"
    fi
done | sort

# Add note about .description files
echo -e "\n${YELLOW}Note:${NC} Directory descriptions are stored in .description files"