# Testing LLM 0.26a0 Tools Feature

This document tracks our exploration of the new tools feature in LLM 0.26a0 (announced at PyCon and in [Simon Willison's blog](https://simonwillison.net/2025/May/14/llm-adds-support-for-tools/)).

## Setup

1. Update dependencies in pyproject.toml:
   - llm>=0.26a0
   - llm-gemini>=0.20a0
   - llm-anthropic>=0.16a0

2. Installation:
   ```bash
   uv venv
   source .venv/bin/activate
   uv pip install -e .
   ```

## Test Plan

### 1. Command-line Tools Tests

- Basic multiplication tool via CLI
  ```bash
  llm --functions '
  def multiply(x: int, y: int) -> int:
      """Multiply two numbers."""
      return x * y
  ' 'what is 123 * 456' -m <available-model>
  ```

- Add debug output to see tool execution
  ```bash
  llm --functions '
  def multiply(x: int, y: int) -> int:
      """Multiply two numbers."""
      return x * y
  ' 'what is 123 * 456' -m <available-model> --tools-debug
  ```

- Test with more complex input/output types
  ```bash
  llm --functions '
  def get_weather(location: str) -> dict:
      """Get the current weather for a location (mock implementation)."""
      return {
          "location": location,
          "temperature": 72,
          "conditions": "sunny",
          "humidity": 45
      }
  ' 'Whats the weather in New York? Is it hot or cold?' -m <available-model>
  ```

### 2. Python API Tests

```python
import llm

def multiply(x: int, y: int) -> int:
    """Multiply two numbers."""
    return x * y

model = llm.get_model("<available-model>")
response = model.chain(
    "What is 123 * 456?",
    tools=[multiply]
)
print(response.text())
```

### 3. Model Compatibility Tests

Test with all available models:
- Claude models (via llm-anthropic)
- Gemini models (via llm-gemini)
- OpenAI models (if available)
- Ollama models (if available)

### 4. Plugin Tool Registration

Investigate how plugins can register tools that can be referenced by name.

## Issues to Track

- [ ] Model compatibility issues
- [ ] Discrepancies between different models' tool implementations
- [ ] Performance implications
- [ ] Error handling with invalid tool inputs or outputs
- [ ] Documentation needs

## Future Enhancements to Consider

- [ ] Support for Python asyncio
- [ ] Integration with our existing templates
- [ ] Custom tool sets for different use cases
- [ ] Structured visualization of tool execution