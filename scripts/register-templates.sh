#!/usr/bin/env bash
set -e  # Exit on error

# Get the full path of this script
SCRIPT_PATH=$(realpath "$0")

echo "Registering all templates..."
for REGISTER_SCRIPT in $(dirname "$SCRIPT_PATH")/register-*.sh; do
    # Skip this script itself
    if [ "$REGISTER_SCRIPT" != "$SCRIPT_PATH" ]; then
        echo "Running: $REGISTER_SCRIPT"
        bash "$REGISTER_SCRIPT" || echo "Warning: $REGISTER_SCRIPT failed"
    fi
done

echo -e "\nAll template registrations complete!"
echo -e "\nAvailable templates:"
llm templates list
