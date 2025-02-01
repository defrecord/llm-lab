"""LLM Lab - Testing environment for LLM tools."""
__version__ = "0.1.0"

from pathlib import Path

ROOT_DIR = Path(__file__).parent.parent.parent
CONFIG_DIR = ROOT_DIR / "config"
TEMPLATES_DIR = ROOT_DIR / "templates"
