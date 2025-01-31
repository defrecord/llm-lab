#!/usr/bin/env bash
# scripts/set_providers.sh
set -euo pipefail

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Provider configurations with API names and URLs
declare -A PROVIDERS=(
    ["gemini"]="GEMINI_API_KEY https://aistudio.google.com/app/apikey"
    ["anthropic"]="ANTHROPIC_API_KEY https://console.anthropic.com/settings/keys"
    ["bedrock"]="AWS_ACCESS_KEY_ID https://console.aws.amazon.com/iamv2/home#/users"
    ["openai"]="OPENAI_API_KEY https://platform.openai.com/api-keys"
)

setup_provider() {
    local provider=$1
    local config=($2)
    local env_var=${config[0]}
    local url=${config[1]}

    echo "Setting up ${provider}"
    echo "Get your key from: ${url}"

    if [ -z "${!env_var:-}" ]; then
        echo -e "${RED}Error: ${env_var} environment variable not set${NC}"
        return 1
    fi

    # Set and verify key
    llm keys set "${provider}" --value "${!env_var}"
    echo "Verifying ${provider} key:"
    echo "${!env_var}" | cut -c 1-10
    local stored
    stored=$(llm keys get "${provider}" | cut -c 1-10)

    if [ "${!env_var:0:10}" = "${stored}" ]; then
        echo -e "${GREEN}✓ Key verified${NC}"
        echo -e "${GREEN}${provider} key set successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Key verification failed${NC}"
        return 1
    fi
}

# Main execution
success=true
for provider in "${!PROVIDERS[@]}"; do
    if ! setup_provider "${provider}" "${PROVIDERS[$provider]}"; then
        success=false
    fi
done

# Summary
echo -e "\n${YELLOW}Setup Summary:${NC}"
for provider in "${!PROVIDERS[@]}"; do
    if llm keys get "${provider}" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ ${provider}${NC}"
    else
        echo -e "${RED}✗ ${provider}${NC}"
    fi
done

$success
