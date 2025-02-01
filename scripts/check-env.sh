#!/bin/bash

check_var() {
    local var_name=$1
    local description=${2:-$var_name}
    if [ -z "${!var_name}" ]; then
        echo "❌ $var_name is not set - $description"
        return 1
    else
        echo "✅ $var_name is set"
        return 0
    fi
}

# API Keys
check_var "ANTHROPIC_API_KEY"
check_var "GEMINI_API_KEY"
check_var "GOOGLE_AI_API_KEY"
check_var "OPENAI_API_KEY"

# AWS Configuration
check_var "AWS_REGION"
check_var "GITHUB_TOKEN"
check_var "AWS_SECRET_ACCESS_KEY"
check_var "AWS_ACCESS_KEY_ID"

# Development Environment
check_var "UV_SYSTEM_PYTHON" "UV System Python"
check_var "PYTHONPATH" "Python Path"

# Count failures
failures=$(env | grep -c "^❌")
if [ $failures -gt 0 ]; then
    echo "Some required environment variables are missing"
    exit 1
fi
