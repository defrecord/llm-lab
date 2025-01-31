# Tool Documentation Paths

## Package Managers
- uv: https://github.com/astral-sh/uv
  - Commands: uv venv, uv pip, uv pip install
  - Config: ~/.config/uv/
  - Docs: https://uv.github.io/

## LLM Tools
- llm: https://llm.datasette.io/
  - Commands: llm models, llm templates
  - Config: ~/.llm/
  - Keys: llm keys set <provider>
  - DB: .llm.db

- ttok: https://github.com/simonw/ttok
  - Commands: ttok, ttok -t N
  - No config needed

- strip-tags: https://github.com/simonw/strip-tags
  - Commands: strip-tags, strip-tags <selector>
  - No config needed

## Environment
- direnv: https://direnv.net/
  - Config: .envrc
  - Allow: direnv allow

## Tool Installation
```bash
# Create and activate environment
uv venv
source .venv/bin/activate

# Install core tools
uv pip install llm ttok strip-tags

# Install providers
uv pip install llm-gemini llm-bedrock llm-claude

# Verify installations
llm models  # List available models
```
