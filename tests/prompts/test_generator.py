#!/usr/bin/env python3
"""Tests for the prompt generation system."""

import pytest
from pathlib import Path
from llm_lab.prompts import ElementRegistry, ModuleConfig, PromptTemplate, PromptGenerator

@pytest.fixture
def element_registry():
    return ElementRegistry()

@pytest.fixture
def module_config(tmp_path):
    return ModuleConfig(str(tmp_path))

@pytest.fixture
def prompt_generator(tmp_path):
    return PromptGenerator(str(tmp_path))

def test_element_registry(element_registry):
    """Test ElementRegistry functionality."""
    # Test getting existing element
    assert "dialogue_history" in element_registry.get_all_elements()
    
    # Test adding new element
    element_registry.add_element("test_element", "Test description")
    assert element_registry.get_element("test_element") == "Test description"

def test_module_config(module_config):
    """Test ModuleConfig functionality."""
    # Test valid module
    assert module_config.validate_module("memory")
    
    # Test invalid module
    assert not module_config.validate_module("invalid_module")
    
    # Test path generation
    path = module_config.get_module_path("memory")
    assert path.name == "memory_prompt.txt"

def test_prompt_template():
    """Test PromptTemplate functionality."""
    elements = {
        "test_element": "Test description"
    }
    template = PromptTemplate("test_module", elements)
    rendered = template.render()
    
    assert "### Test_module Module Prompt ###" in rendered
    assert "**Test_element:**" in rendered
    assert "Test description" in rendered

def test_prompt_generator(prompt_generator, tmp_path):
    """Test PromptGenerator functionality."""
    # Test generating single prompt
    prompt_generator.generate_prompt("memory")
    assert (tmp_path / "memory_prompt.txt").exists()
    
    # Test generating all prompts
    prompt_generator.generate_all_prompts()
    for module in ModuleConfig.MODULES:
        assert (tmp_path / f"{module}_prompt.txt").exists()
    
    # Test invalid module
    with pytest.raises(ValueError):
        prompt_generator.generate_prompt("invalid_module")

def test_prompt_content(prompt_generator, tmp_path):
    """Test generated prompt content."""
    prompt_generator.generate_prompt("memory")
    prompt_path = tmp_path / "memory_prompt.txt"
    
    content = prompt_path.read_text()
    assert "### Memory Module Prompt ###" in content
    assert "**Background_information:**" in content
    assert "**Dialogue_history:**" in content
