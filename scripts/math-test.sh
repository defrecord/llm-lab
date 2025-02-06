#!/bin/bash

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "curl could not be found, installing..."
    sudo apt-get update && sudo apt-get install -y curl
fi

# Generate 3 random numbers between -10 and 10 (smaller numbers for simpler test)
num1=$((RANDOM % 21 - 10))
num2=$((RANDOM % 21 - 10))
num3=$((RANDOM % 21 - 10))

# Create test prompt with explicit instruction
prompt="Calculate exactly: $num1 + $num2 - $num3
Output only the numerical result with no explanation or additional text."

# Function to call Ollama directly
call_ollama() {
    local model=$1
    curl -s -X POST http://localhost:11434/api/generate -d "{
        \"model\": \"$model\",
        \"prompt\": \"$prompt\",
        \"stream\": false
    }" | jq -r '.response' 2>/dev/null
}

# Function to test a model with timeout
test_model() {
    local model=$1
    echo "Testing model: $model"
    echo "Expression: $num1 + $num2 - $num3"
    expected=$((num1 + num2 - num3))
    echo "Expected: $expected"
    
    # Run llm command with timeout
    result=$(timeout 30s llm --no-stream -m "$model" "$prompt" 2>/dev/null | tr -d '\n' | sed 's/[^-0-9]//g')
    
    if [ $? -eq 124 ]; then
        echo "Got: TIMEOUT"
        echo "❌ TIMEOUT"
    else
        echo "Got: $result"
        if [ "$result" = "$expected" ]; then
            echo "✅ CORRECT"
        else
            echo "❌ INCORRECT"
        fi
    fi
    echo "-------------------"
}

# Test each model
echo "=== Math Test ==="
echo "Testing simple arithmetic across models"
echo "Expression: $num1 + $num2 - $num3 = $((num1 + num2 - num3))"
echo "-------------------"

# Test available models
for model in "llama3.2" "deepseek-r1" "gemini-2.0-flash-exp"; do
    test_model "$model"
done