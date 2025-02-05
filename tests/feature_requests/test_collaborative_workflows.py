"""Test the collaborative agent workflow functionality."""

import pytest
from unittest.mock import Mock, patch


def test_agent_creation():
    """Test agent creation and configuration."""
    from llm_lab.agents import create_agent

    config = {
        "role": "code-reviewer",
        "capabilities": ["syntax", "style", "performance"],
        "constraints": ["focus:code-review"],
    }
    agent = create_agent(config)
    assert agent.role == "code-reviewer"
    assert len(agent.capabilities) == 3
    assert agent.is_constrained("focus:code-review")


def test_workflow_execution():
    """Test workflow execution with multiple agents."""
    from llm_lab.workflow import execute_workflow

    workflow = {
        "name": "code-review",
        "agents": ["code-reviewer", "security-analyst"],
        "sequence": "parallel",
    }
    result = execute_workflow(workflow)
    assert result["status"] == "completed"
    assert len(result["agent_results"]) == 2


def test_result_synthesis():
    """Test result synthesis from multiple agents."""
    from llm_lab.workflow import synthesize_results

    results = [
        {"agent": "code-reviewer", "findings": ["style issues"]},
        {"agent": "security-analyst", "findings": ["security risk"]},
    ]
    synthesis = synthesize_results(results)
    assert "summary" in synthesis
    assert len(synthesis["action_items"]) > 0
