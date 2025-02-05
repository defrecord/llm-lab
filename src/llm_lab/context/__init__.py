"""Context management functionality."""


def create_context(config):
    """Create a new context with specified configuration."""

    class Context:
        def __init__(self, id, type, retention, metadata):
            self.id = id
            self.type = type
            self.retention = retention
            self.metadata = metadata

    return Context(
        id=config["id"],
        type=config["type"],
        retention=config["retention"],
        metadata=config["metadata"],
    )


def prune_context(entries, min_relevance):
    """Prune context entries based on relevance."""
    kept = [e for e in entries if e["relevance"] >= min_relevance]
    pruned = [e for e in entries if e["relevance"] < min_relevance]
    return {"kept": kept, "pruned": pruned}


def apply_memory_policy(policy, content):
    """Apply memory management policy to content."""
    from datetime import datetime, timedelta

    retention_days = int(policy["retention"].replace("w", "")) * 7
    return {
        "retention_date": (datetime.now() + timedelta(days=retention_days)).isoformat(),
        "compressed": policy["compression"],
    }
