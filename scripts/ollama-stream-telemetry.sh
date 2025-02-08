#!/bin/bash
# Stream processing with live output and telemetry capture

# Enable debug mode if DEBUG environment variable is set
[[ -n "${DEBUG}" ]] && set -x

# Error handling
set -e
set -o pipefail

# Function to check if Ollama is running
check_ollama() {
    if ! curl -s "http://localhost:11434/api/version" > /dev/null; then
        echo "Error: Cannot connect to Ollama at http://localhost:11434" >&2
        echo "Please ensure Ollama is running and accessible" >&2
        exit 1
    fi
}

# Function to check if model exists
check_model() {
    local model=$1
    if ! curl -s "http://localhost:11434/api/show" -d "{\"name\":\"$model\"}" | jq -e .status > /dev/null; then
        echo "Error: Model '$model' not found" >&2
        echo "Available models:" >&2
        curl -s "http://localhost:11434/api/tags" | jq -r '.models[].name' >&2
        exit 1
    fi
}

# Check dependencies
for cmd in curl jq tee; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' not found" >&2
        exit 1
    fi
done

# Check Ollama connection
check_ollama

# Model to use
MODEL=${MODEL:-"llama2"}  # Default to llama2 if not specified
check_model "$MODEL"

# Debug info
if [[ -n "${DEBUG}" ]]; then
    echo "Debug: Using model $MODEL" >&2
    echo "Debug: Sending request to Ollama..." >&2
fi

# Make the request with error handling and debug output
RESPONSE=$(curl -v -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"prompt\": \"40 - -7 - 6 + 1\"
  }" 2> >(if [[ -n "${DEBUG}" ]]; then cat >&2; else cat > /dev/null; fi))

if [[ -n "${DEBUG}" ]]; then
    echo "Debug: Raw response:" >&2
    echo "$RESPONSE" | jq '.' >&2
fi

echo "$RESPONSE" | \
tee >(jq -r 'select(.response != null) | .response' >&2) | \
jq -c 'select(.done==true) | {
  done_reason,
  total_duration: (.total_duration/1e9),
  eval_count,
  eval_duration: (.eval_duration/1e9)
}'

# Example output:
# 42
# {"done_reason":"stop","total_duration":0.295031,"eval_count":485,"eval_duration":0.13461}