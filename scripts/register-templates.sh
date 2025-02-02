#!/bin/bash
set -euo pipefail

# set the base dir
BASEDIR=$(dirname "$0")
# echo "Base dir is $BASEDIR"
# Loop through all register-template*.sh files in the base directory.
find "$BASEDIR" -maxdepth 1 -type f -name "register-*.sh" -print0 |
    while IFS= read -r -d $'\0' script_file; do
        # Check if the script_file is the current script
        if [[ "$script_file" != "$0" ]]; then
            echo "Running: $script_file"
            "$script_file"
        fi
done
