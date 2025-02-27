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
        cmd+=" --proxy \"${HTTP_PROXY}\""
        # Add custom headers for mitmproxy filtering
        cmd+=" -H \"X-Request-ID: ollama-telemetry\""
        cmd+=" -H \"X-Client-Type: ollama-cli\""
        [[ -n "${DEBUG}" ]] && echo "Debug: Using HTTP proxy: ${HTTP_PROXY}" >&2
    fi
    
    # Add common options
    cmd+=" -s"                        # silent mode
    cmd+=" --compressed"              # handle compressed responses
    cmd+=" --tcp-nodelay"            # optimize for streaming
    cmd+=" -H \"Accept-Encoding: gzip, deflate\"" # explicit encoding
    cmd+=" -w \"%{time_connect},%{time_starttransfer},%{time_total}\"" # timing metrics
    [[ -n "${DEBUG}" ]] && cmd+=" -v" # verbose in debug mode
    
    # Add user agent for tracking in mitmproxy
    cmd+=" -A \"ollama-telemetry/1.0 (telemetry-script)\"" 
    
    # Add retry logic with exponential backoff
    cmd+=" --retry 3"
    cmd+=" --retry-delay 1"
    cmd+=" --retry-max-time 30"
    
    echo "$cmd"
}

# Function to check if Ollama is running and determine connection details
check_ollama() {
    local curl_cmd=$(build_curl_cmd)
    
    # First try local connection
    if ! $curl_cmd "http://localhost:11434/api/version" > /dev/null; then
        # If local fails and we have a proxy, try through host.docker.internal
        if [[ -n "${HTTP_PROXY}" ]]; then
            [[ -n "${DEBUG}" ]] && echo "Debug: Local connection failed, trying through host.docker.internal" >&2
            # Update to use host.docker.internal instead of localhost
            OLLAMA_HOST="host.docker.internal"
            if $curl_cmd "http://${OLLAMA_HOST}:11434/api/version" > /dev/null; then
                [[ -n "${DEBUG}" ]] && echo "Debug: Successfully connected to Ollama through ${OLLAMA_HOST}" >&2
                export OLLAMA_HOST
                return 0
            fi
        fi
        echo "Error: Cannot connect to Ollama" >&2
        echo "- Tried localhost:11434" >&2
        [[ -n "${HTTP_PROXY}" ]] && echo "- Tried ${OLLAMA_HOST}:11434 through ${HTTP_PROXY}" >&2
        echo "Please ensure Ollama is running and accessible" >&2
        exit 1
    fi
    OLLAMA_HOST="localhost"
    export OLLAMA_HOST
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
    # Simulate streaming responses with properly formatted JSON
    RESPONSE='{
      "model":"llama3.2:latest",
      "created_at":"2025-02-08T02:59:33.336236Z",
      "response":"The",
      "done":false
    }
{
      "model":"llama3.2:latest",
      "created_at":"2025-02-08T02:59:33.354739Z",
      "response":" answer",
      "done":false
    }
{
      "model":"llama3.2:latest",
      "created_at":"2025-02-08T02:59:33.373535Z",
      "response":" is",
      "done":false
    }
{
      "model":"llama3.2:latest",
      "created_at":"2025-02-08T02:59:33.392696Z",
      "response":" 42",
      "done":false
    }
{
      "model":"llama3.2:latest",
      "created_at":"2025-02-08T02:59:34.950514Z",
      "response":"",
      "done":true,
      "done_reason":"stop",
      "total_duration":295031000,
      "prompt_eval_count":35,
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
    
    # Make the request with explicit accept header for streaming
    RESPONSE=$($curl_cmd \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Accept: application/x-ndjson" \
      --connect-timeout 10 \
      --max-time 300 \
      http://localhost:11434/api/generate \
      -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"40 - -7 - 6 + 1\",
        \"stream\": true
      }" 2> >(if [[ -n "${DEBUG}" ]]; then cat >&2; else cat > /dev/null; fi))
fi

if [[ -n "${DEBUG}" ]]; then
    echo "Debug: Raw response:" >&2
    echo "$RESPONSE" | jq '.' >&2
fi

# Process the response through two parallel streams:
#
# Stream 1: Content output
# - Extract only response content
# - Display incrementally to stderr for live output
echo "$RESPONSE" | jq -r 'select(.response != null) | .response' >&2

# Stream 2: Telemetry metrics
# - Wait for completion (done=true)
# - Extract and format relevant metrics
# - Output as structured JSON to stdout
echo "$RESPONSE" | jq -c 'select(.done==true) | {
  timestamp: .created_at,
  model: .model,
  done_reason,
  telemetry: {
    time: {
      total_duration_sec: (.total_duration/1e9),
      eval_duration_sec: (.eval_duration/1e9),
      connect_time: (input | split(",") | .[0] | tonumber),
      time_to_first_byte: (input | split(",") | .[1] | tonumber),
      total_transfer_time: (input | split(",") | .[2] | tonumber)
    },
    tokens: {
      prompt_tokens: .prompt_eval_count,
      completion_tokens: .eval_count,
      tokens_sec: (.eval_count / (.eval_duration/1e9))
    },
    network: {
      proxy_enabled: (env.HTTP_PROXY != null),
      proxy_url: env.HTTP_PROXY,
      host: env.OLLAMA_HOST
    }
  }
}'

# Example output:
# 42
# {"done_reason":"stop","total_duration":0.295031,"eval_count":485,"eval_duration":0.13461}