#!/usr/bin/env python3
"""
Modular Prompt Generation System for LLM Lab.

This module implements a structured system for generating and managing
modular prompts across different components of the LLM lab.
"""

import os
from pathlib import Path
from typing import Dict, List, Optional
import yaml

class ElementRegistry:
    """Manages the core elements used in prompt generation."""
    
    def __init__(self):
        self.elements = {
            "background_information": "Essential data and objectives pertinent to the experimental setup.",
            "dialogue_history": "Tracks participant dialogues.",
            "violation_log": "Tracks instances of detection by the supervisor.",
            "regulations": "Rules and constraints formulated by the Reflection and Summary modules.",
            "guidance": "Assists agents in stealthily disseminating information.",
            "plan": "A strategy formulated by the Reflection and Summary modules.",
            "instructions": "Specific tasks for the LLM within each module."
        }
    
    def get_element(self, name: str) -> Optional[str]:
        """Get the description for a specific element."""
        return self.elements.get(name)
    
    def add_element(self, name: str, description: str) -> None:
        """Add a new element to the registry."""
        self.elements[name] = description
    
    def get_all_elements(self) -> Dict[str, str]:
        """Get all registered elements."""
        return self.elements.copy()

class ModuleConfig:
    """Manages module configuration and validation."""
    
    MODULES = ["memory", "dialogue", "reflection", "summary"]
    
    def __init__(self, output_dir: str = "prompts"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
    def get_module_path(self, module: str) -> Path:
        """Get the output path for a specific module."""
        return self.output_dir / f"{module}_prompt.txt"
    
    def validate_module(self, module: str) -> bool:
        """Validate that a module name is valid."""
        return module in self.MODULES

class PromptTemplate:
    """Handles prompt template rendering and formatting."""
    
    def __init__(self, module: str, elements: Dict[str, str]):
        self.module = module
        self.elements = elements
    
    def render(self) -> str:
        """Render the prompt template with all elements."""
        content = [f"### {self.module.title()} Module Prompt ###\n"]
        for element, description in self.elements.items():
            content.append(f"**{element.title()}:**")
            content.append(description + "\n")
        return "\n".join(content)

class PromptGenerator:
    """Main class for generating module prompts."""
    
    def __init__(self, output_dir: str = "prompts"):
        self.registry = ElementRegistry()
        self.config = ModuleConfig(output_dir)
    
    def generate_prompt(self, module: str) -> None:
        """Generate a prompt for a specific module."""
        if not self.config.validate_module(module):
            raise ValueError(f"Invalid module: {module}")
            
        template = PromptTemplate(module, self.registry.get_all_elements())
        output_path = self.config.get_module_path(module)
        
        with open(output_path, 'w') as f:
            f.write(template.render())
    
    def generate_all_prompts(self) -> None:
        """Generate prompts for all modules."""
        for module in self.config.MODULES:
            self.generate_prompt(module)

def main():
    """Main entry point for prompt generation."""
    generator = PromptGenerator()
    generator.generate_all_prompts()
    print("All prompts have been generated successfully.")

if __name__ == "__main__":
    main()
