"""Core functionality tests for LLM Lab."""

import os
from pathlib import Path


def test_core_directories():
    """Test that core directories are created and accessible."""
    from llm_lab import ROOT_DIR, DATA_DIR, CONFIG_DIR

    dirs = [ROOT_DIR, DATA_DIR, CONFIG_DIR]
    for dir_path in dirs:
        assert isinstance(dir_path, Path)
        assert dir_path.exists()
        assert dir_path.is_dir()


def test_version():
    """Test that version is defined."""
    from llm_lab import __version__

    assert isinstance(__version__, str)
    assert "." in __version__  # Simple version format check
