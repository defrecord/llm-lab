"""Baseline and performance tests for LLM Lab."""
import json
from pathlib import Path

import pytest

from llm_lab import DATA_DIR
from llm_lab.utils import get_model_response, load_json, save_json

BASELINE_TIMEOUT = 30  # Seconds to wait for model responses

def test_model_consistency():
    """Test response consistency across models."""
    prompt = "Explain recursion"
    models = ["gemini-1.5-pro-latest", "gpt-4", "claude-3"]
    
    results = {}
    for model in models:
        response = get_model_response(prompt, model)
        if "error" in response:
            pytest.skip(f"Model {model} failed: {response['error']}")
        results[model] = response
    
    # Check response lengths are within 20%
    lengths = [len(r["text"]) for r in results.values()]
    assert max(lengths) / min(lengths) < 1.2, \
        f"Response length variance too high: {lengths}"


@pytest.mark.timeout(BASELINE_TIMEOUT)
def test_performance_regression():
    """Compare against baseline metrics."""
    baseline_file = DATA_DIR / "baselines" / "performance.json"
    if not baseline_file.exists():
        pytest.skip(f"No baseline file: {baseline_file}")
    
    # Run test cases
    test_cases = [
        "Explain recursion",
        "What is dependency injection?",
        "How do generators work?"
    ]
    
    results = []
    for prompt in test_cases:
        response = get_model_response(prompt)
        if "error" not in response:
            results.append(response)
    
    if not results:
        pytest.skip("No successful responses")
    
    current = {
        "latency": sum(r["latency"] for r in results) / len(results),
        "tokens": sum(r["tokens"] for r in results) / len(results)
    }
    
    baseline = load_json(baseline_file)
    
    # Allow 10% regression from baseline
    assert current["latency"] <= baseline["latency"] * 1.1, \
        f"Latency regression: {current['latency']:.2f}s > {baseline['latency']:.2f}s"
    assert current["tokens"] <= baseline["tokens"] * 1.1, \
        f"Token count regression: {current['tokens']} > {baseline['tokens']}"
