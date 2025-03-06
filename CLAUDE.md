# LLM Lab Development Guidelines

## Build & Test Commands
- `make test` - Run all tests
- `make format` - Format code with black
- `make lint` - Run linters (black --check and ruff)
- `UV_SYSTEM_PYTHON=1 uv run pytest tests` - Run all tests directly
- Single test: `UV_SYSTEM_PYTHON=1 uv run pytest tests/path/to/test_file.py::test_function_name`
- `make clean` - Reset environment
- `make sanity` - Comprehensive checks

## Code Style
- **Formatting**: Black for code, Ruff for linting
- **Imports**: stdlib first, third-party second, local modules last
- **Types**: Use type annotations with standard library typing
- **Naming**: snake_case (functions/variables), PascalCase (classes), UPPER_CASE (constants)
- **Error handling**: Use specific exception types with helpful messages
- **Commits**: Follow conventional commits format

## Project Structure
- Uses src layout pattern
- Modules organized by functionality in src/llm_lab/
- Tests mirror the package structure in tests/
- Configuration in pyproject.toml

## Important Notes
- **Git commits**: Never use GPG signing in commits (`git commit -S` or `-S` flag) as this will freeze the UI