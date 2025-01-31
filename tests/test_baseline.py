import pytest
from pathlib import Path

def test_model_consistency():
    """Test response consistency across models."""
    prompt = "Explain recursion"
    models = ["gemini-1.5-pro-latest", "gpt-4", "claude-3"]
    results = compare_responses(prompt, models)
    
    # Check response lengths are within 20%
    lengths = [len(r["response"]) for r in results.values()]
    assert max(lengths) / min(lengths) < 1.2

def test_performance_regression():
    """Compare against baseline metrics."""
    current = run_benchmark()
    baseline = load_baseline("performance")
    
    assert current["latency"] <= baseline["latency"] * 1.1
    assert current["tokens"] <= baseline["tokens"] * 1.1
