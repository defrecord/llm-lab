"""Utility functions for LLM Lab."""
import json
from pathlib import Path
from typing import Any

import llm
from llm_lab import DATA_DIR

def load_json(path: Path) -> dict[str, Any]:
    """Load JSON data from file."""
    with open(path) as f:
        return json.load(f)

def save_json(data: dict[str, Any], path: Path) -> None:
    """Save data as JSON to file."""
    path.parent.mkdir(exist_ok=True, parents=True)
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)

def get_model_response(prompt: str, model: str | None = None) -> dict[str, Any]:
    """Get response from LLM model with metrics."""
    try:
        response = llm.complete(prompt, model=model)
        return {
            "text": response.text(),
            "tokens": response.tokens,
            "latency": response.completion_ms / 1000.0  # Convert to seconds
        }
    except Exception as e:
        return {"error": str(e)}

def save_baseline(name: str, data: dict[str, Any]) -> None:
    """Save baseline metrics."""
    baseline_dir = DATA_DIR / "baselines"
    baseline_dir.mkdir(exist_ok=True)
    save_json(data, baseline_dir / f"{name}.json")
