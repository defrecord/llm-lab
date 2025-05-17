#!/usr/bin/env python3
"""
Test script for LLM 0.26a0 tools feature.

Usage:
    uv run python scripts/test_llm_tools.py [model_name]

Example:
    uv run python scripts/test_llm_tools.py claude-3-haiku
    uv run python scripts/test_llm_tools.py gemini-2.0-flash
"""
import sys
import json
import time
import llm

def multiply(x: int, y: int) -> int:
    """Multiply two numbers."""
    print(f"Tool called: multiply({x}, {y})")
    result = x * y
    print(f"Result: {result}")
    return result

def get_weather(location: str) -> dict:
    """Get the current weather for a location (mock implementation)."""
    print(f"Tool called: get_weather(\"{location}\")")
    result = {
        "location": location,
        "temperature": 72,
        "conditions": "sunny",
        "humidity": 45
    }
    print(f"Result: {json.dumps(result, indent=2)}")
    return result

def run_test(model_name, prompt, tool):
    """Run a test with the specified model, prompt and tool."""
    try:
        model = llm.get_model(model_name)
        print(f"\nUsing model: {model.model_id}")
        print(f"Prompt: {prompt}")
        
        start_time = time.time()
        response = model.chain(prompt, tools=[tool])
        end_time = time.time()
        
        result = response.text().strip()
        print(f"Response: {result}")
        print(f"Time taken: {end_time - start_time:.2f} seconds")
        return True
    except Exception as e:
        print(f"Error testing with {model_name}: {e}")
        return False

def main():
    model_name = sys.argv[1] if len(sys.argv) > 1 else "claude-3-haiku"
    
    print("\n" + "="*50)
    print(f"Testing LLM 0.26a0 tools feature with {model_name}")
    print("="*50)
    
    # Test 1: Basic multiplication
    print("\n--- Test 1: Basic Multiplication ---")
    prompt = "What is 123 * 456? Use the multiply tool to calculate it exactly."
    run_test(model_name, prompt, multiply)
    
    # Test 2: Complex multiplication
    print("\n--- Test 2: Complex Multiplication ---")
    prompt = "What is 123456789 * 987654321? Use the multiply tool to calculate it exactly."
    run_test(model_name, prompt, multiply)
    
    # Test 3: Weather data
    print("\n--- Test 3: Weather Data ---")
    prompt = "What's the weather in New York? Is it hot or cold based on the temperature?"
    run_test(model_name, prompt, get_weather)
    
    # Test 4: Tool selection
    print("\n--- Test 4: Tool Selection ---")
    prompt = "First tell me the weather in Boston, then calculate 42 * 73."
    success = run_test(model_name, prompt, get_weather)
    
    if success:
        print("\nAll tests completed.")
    
if __name__ == "__main__":
    main()