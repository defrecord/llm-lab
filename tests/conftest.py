"""Test configuration and fixtures."""
import pytest
from pathlib import Path

@pytest.fixture
def project_root() -> Path:
    """Return the project root directory."""
    return Path(__file__).parent.parent

@pytest.fixture
def config_dir(project_root: Path) -> Path:
    """Return the config directory."""
    return project_root / "config"

@pytest.fixture
def templates_dir(project_root: Path) -> Path:
    """Return the templates directory."""
    return project_root / "templates"
