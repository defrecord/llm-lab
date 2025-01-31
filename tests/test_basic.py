"""Basic test suite for LLM Lab."""
from pathlib import Path
import pytest
import yaml

from llm_lab import ROOT_DIR, CONFIG_DIR, TEMPLATES_DIR

def test_config_exists():
    """Test that default config exists."""
    assert (CONFIG_DIR / "default.yaml").exists()

def test_template_exists():
    """Test that basic template exists."""
    assert (TEMPLATES_DIR / "basic.yaml").exists()

def test_template_valid():
    """Test that basic template is valid."""
    with open(TEMPLATES_DIR / "basic.yaml") as f:
        template = yaml.safe_load(f)
    assert "name" in template
    assert "parameters" in template
    assert any(p["name"] == "input" for p in template["parameters"])
