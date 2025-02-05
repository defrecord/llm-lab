"""LLM Lab - Testing environment for exploring LLM CLI tools."""

from pathlib import Path

__version__ = "0.1.0"

# Core paths
ROOT_DIR = Path(__file__).parent.parent.parent
CONFIG_DIR = ROOT_DIR / "config"
TEMPLATES_DIR = ROOT_DIR / "templates"
DATA_DIR = ROOT_DIR / "data"
SIN_DIR = DATA_DIR / "sin"
IMAGES_DIR = DATA_DIR / "images"

# Ensure core data directories exist
for dir_path in [DATA_DIR, SIN_DIR, IMAGES_DIR]:
    dir_path.mkdir(exist_ok=True, parents=True)
