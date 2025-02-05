"""Basic test suite for LLM Lab."""

from pathlib import Path

import pytest
import yaml

from llm_lab import (
    CONFIG_DIR,
    DATA_DIR,
    IMAGES_DIR,
    ROOT_DIR,
    SIN_DIR,
    TEMPLATES_DIR,
    __version__,
)


def test_version():
    """Test that version is a string."""
    assert isinstance(__version__, str)
    assert "0.1.0" == __version__  # Match pyproject.toml version


def test_directories_exist():
    """Test that required directories exist."""
    dirs = [ROOT_DIR, CONFIG_DIR, TEMPLATES_DIR, DATA_DIR, SIN_DIR, IMAGES_DIR]
    for dir_path in dirs:
        assert dir_path.exists(), f"Directory not found: {dir_path}"
        assert dir_path.is_dir(), f"Not a directory: {dir_path}"


def test_config_exists():
    """Test that model config exists."""
    config_file = CONFIG_DIR / "model.conf"
    assert config_file.exists(), f"Config file not found: {config_file}"


def test_template_valid(templates_dir):
    """Test that templates are valid YAML."""
    template_files = list(templates_dir.glob("*.yaml"))
    if not template_files:
        pytest.skip("No template files found")

    for template_file in template_files:
        try:
            with open(template_file) as f:
                template = yaml.safe_load(f)
            assert isinstance(
                template, dict
            ), f"Template {template_file.name} is not a dictionary"
            assert (
                "system" in template
            ), f"Template {template_file.name} missing 'system' key"
        except yaml.YAMLError as e:
            pytest.fail(f"Failed to parse {template_file.name}: {e}")
        except Exception as e:
            pytest.fail(f"Error processing {template_file.name}: {e}")
