#!/bin/bash
for provider in gemini anthropic bedrock openai; do
  if [ -n "${!provider^^}_API_KEY" ]; then
    llm keys set "$provider" --value "${!provider^^}_API_KEY"
  fi
done
