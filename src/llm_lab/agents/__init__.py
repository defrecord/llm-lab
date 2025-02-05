"""Collaborative agent system functionality."""


def create_agent(config):
    """Create an agent with specified configuration."""

    class Agent:
        def __init__(self, role, capabilities, constraints):
            self.role = role
            self.capabilities = capabilities
            self._constraints = constraints

        def is_constrained(self, constraint):
            return constraint in self._constraints

    return Agent(
        role=config["role"],
        capabilities=config["capabilities"],
        constraints=config["constraints"],
    )
