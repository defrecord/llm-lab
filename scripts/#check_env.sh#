#!/usr/bin/env bash
# scripts/check_env.sh

set -euo pipefail

# Required environment variables
declare -A REQUIRED_VARS=(
    ["OPENAI_API_KEY"]="OpenAI API key"
    ["GEMINI_API_KEY"]="Gemini API key"
    ["GOOGLE_AI_API_KEY"]="Google AI API key"
    ["ANTHROPIC_API_KEY"]="Anthropic API key"
    ["AWS_ACCESS_KEY_ID"]="AWS Access Key ID"
    ["AWS_REGION"]="AWS Region"
    ["AWS_SECRET_ACCESS_KEY"]="AWS Secret Access Key"
    ["GITHUB_TOKEN"]="GitHub Token"
    ["PYTHONPATH"]="Python Path"
    ["UV_SYSTEM_PYTHON"]="UV System Python"
)

# Check each variable
all_set=true
for var in "${!REQUIRED_VARS[@]}"; do
    if [ -n "${!var:-}" ]; then
        echo "✅ $var is set"
    else
        echo "❌ $var is not set - ${REQUIRED_VARS[$var]}"
        all_set=false
    fi
done

# Final status
if $all_set; then
    echo "All required environment variables are set"
    exit 0
else
    echo "Some required environment variables are missing"
    exit 1
fi

