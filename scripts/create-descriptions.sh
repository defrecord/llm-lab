#!/usr/bin/env bash

declare -A descriptions=(
    ["data"]="Metrics, logs, baselines"
    ["scripts"]="Setup and utility scripts"
    ["src"]="Core library code"
    ["templates"]="LLM prompt templates"
    ["tests"]="Test suite"
)

for dir in "${!descriptions[@]}"; do
    if [ -d "$dir" ]; then
        echo "${descriptions[$dir]}" > "$dir/.description"
        
        if [ ! -f "$dir/README.org" ]; then
            echo "#+title: ${dir^}" > "$dir/README.org"
            echo "" >> "$dir/README.org"
            echo "${descriptions[$dir]}" >> "$dir/README.org"
        fi
    fi
done
