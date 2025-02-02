#!/bin/bash

# Configuration
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
MAKEFILE="${REPO_ROOT}/Makefile"
BACKUP="${MAKEFILE}.bak"

# Create backup
cp "${MAKEFILE}" "${BACKUP}"

# First, ensure all command lines start with a tab
sed -i.tmp '/^[[:space:]]\+@\|^[[:space:]]\+[^[:space:]#]/ s/^[[:space:]]\+/\t/' "${MAKEFILE}"

# Then use Emacs in batch mode to clean up the rest of whitespace
emacs --batch "${MAKEFILE}" \
    --eval "(require 'whitespace)" \
    --eval "(setq-default indent-tabs-mode t)" \
    --eval "(setq tab-width 8)" \
    --eval "(progn
             (makefile-mode)
             (whitespace-cleanup)
             (save-buffer))" \
    --kill

# Verify the Makefile is valid
if make -n > /dev/null 2>&1; then
    echo "Makefile cleanup successful!"
    rm "${BACKUP}"
else
    echo "Error: Makefile validation failed. Restoring backup..."
    mv "${BACKUP}" "${MAKEFILE}"
    exit 1
fi