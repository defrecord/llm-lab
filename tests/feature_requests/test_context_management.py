"""Test the advanced context management functionality."""

import pytest
from unittest.mock import Mock, patch


def test_context_creation():
    """Test context creation and initialization."""
    from llm_lab.context import create_context

    config = {
        "id": "test-context",
        "type": "long-term",
        "retention": "1w",
        "metadata": {"project": "test"},
    }
    context = create_context(config)
    assert context.id == "test-context"
    assert context.type == "long-term"
    assert context.retention == "1w"
    assert context.metadata["project"] == "test"


def test_context_pruning():
    """Test context pruning functionality."""
    from llm_lab.context import prune_context

    entries = [
        {"content": "test1", "relevance": 0.9},
        {"content": "test2", "relevance": 0.5},
    ]
    result = prune_context(entries, min_relevance=0.7)
    assert len(result["kept"]) == 1
    assert len(result["pruned"]) == 1
    assert result["kept"][0]["relevance"] > 0.7


def test_memory_management():
    """Test memory management policies."""
    from llm_lab.context import apply_memory_policy

    policy = {"retention": "1w", "compression": True, "priority": "normal"}
    result = apply_memory_policy(policy, "test-content")
    assert "retention_date" in result
    assert result["compressed"] is True
