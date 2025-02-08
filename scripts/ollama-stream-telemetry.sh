#!/bin/bash
# Stream processing with live output and telemetry capture

# Enable debug mode if DEBUG environment variable is set
[[ -n "${DEBUG}" ]] && set -x

# Error handling
set -e
set -o pipefail

# Function to build curl command with proxy settings
build_curl_cmd() {
    local cmd="curl"
    
    # Add proxy settings if they exist
    if [[ -n "${HTTP_PROXY}" ]]; then
        cmd+=" --proxy ${HTTP_PROXY}"
        [[ -n "${DEBUG}" ]] && echo "Debug: Using HTTP proxy: ${HTTP_PROXY}" >&2
    fi
    
    # Add common options
    cmd+=" -s"
    [[ -n "${DEBUG}" ]] && cmd+=" -v"
    
    echo "$cmd"
}

# Function to check if Ollama is running
check_ollama() {
    local curl_cmd=$(build_curl_cmd)
    if ! $curl_cmd "http://localhost:11434/api/version" > /dev/null; then
        echo "Error: Cannot connect to Ollama at http://localhost:11434" >&2
        echo "Please ensure Ollama is running and accessible" >&2
        if [[ -n "${HTTP_PROXY}" ]]; then
            echo "Using proxy: ${HTTP_PROXY}" >&2
        fi
        exit 1
    fi
}

# Function to get model name from available models
get_available_model() {
    local preferred_model=$1
    local curl_cmd=$(build_curl_cmd)
    
    # Get list of available models
    local models=$($curl_cmd "http://localhost:11434/api/tags" | jq -r '.models[].name')
    
    # If preferred model exists, use it
    if echo "$models" | grep -q "^${preferred_model}$"; then
        echo "$preferred_model"
        return 0
    fi
    
    # Try finding the first matching model (case insensitive)
    local matched_model=$(echo "$models" | grep -i "^${preferred_model}" | head -n 1)
    if [[ -n "$matched_model" ]]; then
        echo "$matched_model"
        return 0
    fi
    
    # If MODEL_AUTO_SELECT is set, use the first available model
    if [[ -n "${MODEL_AUTO_SELECT}" ]]; then
        local first_model=$(echo "$models" | head -n 1)
        echo "Warning: Model '$preferred_model' not found, using '$first_model'" >&2
        echo "$first_model"
        return 0
    fi
    
    # Otherwise show error and available models
    echo "Error: Model '$preferred_model' not found" >&2
    echo "Available models:" >&2
    echo "$models" >&2
    exit 1
}

# Check dependencies
for cmd in curl jq tee; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' not found" >&2
        exit 1
    fi
done

# Check if we should use mock data
if [[ -n "${MOCK}" ]]; then
    if [[ -n "${DEBUG}" ]]; then
        echo "Debug: Using mock data" >&2
    fi
    # Simulate streaming response
    RESPONSE='{
      "model":"llama3.2",
      "response":"42",
      "done":true,
      "total_duration":295031000,
      "eval_count":485,
      "eval_duration":134610000
    }'
else
    # Check Ollama connection
    check_ollama

    # Get available model
    MODEL=$(get_available_model "${MODEL:-llama3.2}")
fi

# Debug info
if [[ -n "${DEBUG}" ]]; then
    echo "Debug: Using model $MODEL" >&2
    echo "Debug: Sending request to Ollama..." >&2
fi

# Make the request with error handling and debug output
if [[ -z "${MOCK}" ]]; then
    # Build curl command with proxy settings
    curl_cmd=$(build_curl_cmd)
    
    # Debug info about request
    if [[ -n "${DEBUG}" ]]; then
        echo "Debug: Curl command: $curl_cmd" >&2
        if [[ -n "${HTTP_PROXY}" ]]; then
            echo "Debug: Using proxy for request: ${HTTP_PROXY}" >&2
        fi
    fi
    
    # Make the request
    RESPONSE=$($curl_cmd -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"40 - -7 - 6 + 1\"
      }" 2> >(if [[ -n "${DEBUG}" ]]; then cat >&2; else cat > /dev/null; fi))
fi

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