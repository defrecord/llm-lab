#!/bin/bash
# Stream processing with live output and telemetry capture

curl -s -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2",
    "prompt": "40 - -7 - 6 + 1"
  }' | \
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