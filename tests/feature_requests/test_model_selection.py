"""Test the automated model selection functionality."""

import pytest
from unittest.mock import Mock, patch


def test_task_analysis():
    """Test basic task analysis functionality."""
    from llm_lab.auto_model import analyze_task

    task = "Generate unit tests for authentication module"
    result = analyze_task(task)
    assert "complexity" in result
    assert "domain" in result
    assert isinstance(result["complexity"], float)


def test_model_selection():
    """Test model selection based on task requirements."""
    from llm_lab.auto_model import select_model

    requirements = {
        "task_type": "code-generation",
        "min_accuracy": 0.9,
        "max_cost": 0.05,
    }
    model = select_model(requirements)
    assert model is not None
    assert hasattr(model, "cost_per_1k")
    assert model.cost_per_1k <= requirements["max_cost"]


def test_performance_tracking():
    """Test performance history tracking."""
    from llm_lab.auto_model import track_performance

    result = track_performance(
        model="test-model", task="test-task", success=True, latency=1.5, tokens=100
    )
    assert result["recorded"] is True
    assert "timestamp" in result
