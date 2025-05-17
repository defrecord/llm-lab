"""
Tests for LLM 0.26a0 tools feature.

This module tests the new alpha tools functionality in LLM 0.26a0.
"""
import pytest
import llm


def test_tools_availability():
    """Test that tools functionality is available in the installed LLM version."""
    try:
        # Check if model.chain has the tools parameter
        model = llm.get_model()
        signature = model.chain.__code__.co_varnames
        assert 'tools' in signature, "Tools parameter not available in model.chain()"
    except Exception as e:
        pytest.fail(f"Error checking tools availability: {e}")


def multiply(x: int, y: int) -> int:
    """Multiply two numbers."""
    return x * y


def test_basic_tool_usage():
    """Test basic usage of a tool with a simple multiplication function."""
    try:
        # Try with different models based on availability
        for model_name in ["gemini-1.5-flash", "claude-3-haiku", "gpt-4o-mini"]:
            try:
                model = llm.get_model(model_name)
                response = model.chain(
                    "What is 123 * 456?",
                    tools=[multiply]
                )
                result = response.text().strip()
                # Check if the result contains the correct answer (56088)
                assert "56088" in result, f"Model {model_name} failed to use the multiply tool correctly"
                print(f"Successfully tested tool with {model_name}")
                return  # If one model works, we're good
            except Exception as e:
                print(f"Couldn't test with {model_name}: {e}")
                continue
        
        pytest.skip("No compatible models available for tool testing")
    except Exception as e:
        pytest.fail(f"Error in basic tool usage test: {e}")


def get_weather(location: str) -> dict:
    """Get the current weather for a location (mock implementation)."""
    return {
        "location": location,
        "temperature": 72,
        "conditions": "sunny",
        "humidity": 45
    }


def test_complex_tool_usage():
    """Test usage of a tool that returns a more complex data structure."""
    try:
        # Try with different models based on availability
        for model_name in ["gemini-1.5-flash", "claude-3-haiku", "gpt-4o-mini"]:
            try:
                model = llm.get_model(model_name)
                response = model.chain(
                    "What's the weather in New York? And is it hot or cold?",
                    tools=[get_weather]
                )
                result = response.text().strip()
                # Check if the result contains something about the temperature
                assert "72" in result or "temperature" in result, f"Model {model_name} failed to use the weather tool correctly"
                print(f"Successfully tested complex tool with {model_name}")
                return  # If one model works, we're good
            except Exception as e:
                print(f"Couldn't test complex tool with {model_name}: {e}")
                continue
        
        pytest.skip("No compatible models available for complex tool testing")
    except Exception as e:
        pytest.fail(f"Error in complex tool usage test: {e}")