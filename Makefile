# Color codes
CYAN := \033[36m
RESET := \033[0m

# Help pattern - any line starting with "##"
.DEFAULT_GOAL := help
help:  ## Display this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'

.PHONY: init test clean tangle docs

init: tangle ## Initialize project with UV
	@echo "Initializing project..."
	@uv venv
	@. .venv/bin/activate && uv pip install -r requirements.txt

venv: ## Create virtualenv
	uv venv
	. .venv/bin/activate

.PHONY: install check clean

install:
	uv run pip install -r requirements.txt
	uv run pip install -r dev-requirements.txt

check:
	@uv run llm --version
	@uv run ttok --version
	@uv run strip-tags --version
	@uv run files-to-prompt --version

test: ## Run test suite
	@echo "Running tests..."
	@uv run pytest tests/

lint: ## Lint
	@uv run black src

clean: ## Clean generated files
	@echo "Cleaning..."
	@rm -rf .venv build dist *.egg-info __pycache__ .pytest_cache

emacs: ## Run Emacs
	@emacs -l .emacs.d/init.el

tangle: ## Tangle all org files
	@echo "Tangling org files..."
	@emacs --batch \
	--eval "(require 'org)" \
	--eval "(dolist (file (directory-files \".\" t \"\\.org$$\")) \
	(with-current-buffer (find-file file) \
	(org-babel-tangle)))" \
	--kill

docs: ## Generate documentation
	@echo "Generating docs..."
	@emacs --batch \
	--eval "(require 'org)" \
	--eval "(dolist (file (directory-files \"docs\" t \"\\.org$$\")) \
	(with-current-buffer (find-file file) \
	(org-babel-tangle)))" \
	--killg

check-env: scripts/check-env.sh ## Check environment variables
	@echo "Checking environment..."
	@./scripts/check-env.sh


llm-model-default: ## Use Ollama+Computer Use or gemini-2.0-flash-thinking-exp-01-21+Replit
	llm models default llama3.2

scripts/register-session-agent-template.sh: prompts/session-agent.md

session-agent: scripts/register-session-agent-template.sh ## Interactively track status using llama3.2 model
	@./scripts/register-session-agent-template.sh
	@llm chat -c -t session-agent

session-agent-manual: scripts/register-session-agent-template.sh ## Register session agent template manually
	@./scripts/register-session-agent-template.sh --manual
	@llm chat -c -t session-agent

register-commit-template: scripts/register-commit-template.sh ## Register the commit message template
	@echo "Registering commit message template..."
	@./scripts/register-commit-template.sh

.PHONY: register-templates
register-templates: ## Register all templates from scripts/register-* files
	@echo "Registering all templates..."
	@for script in scripts/register-*.sh; do \
	if [ -x "$$script" ]; then \
	echo "Running $${script}..."; \
	if ! ./$$script; then \
	echo "Warning: $$script failed, continuing..."; \
	fi \
	else \
	echo "Warning: $$script not executable, skipping..."; \
	fi \
	done
	@echo "Template registration complete."
	@echo "Available templates:"
	@llm templates list

makefile-cleanup: scripts/makefile-cleanup.sh ## Clean up Makefile formatting
	@echo "Cleaning up Makefile formatting..."
	@./scripts/makefile-cleanup.sh

check-coverage: scripts/check-llm-coverage.sh ## Check LLM command coverage in examples
	@echo "Analyzing LLM command coverage..."
	@./scripts/check-llm-coverage.sh
	@echo "Coverage report available in data/spider/simonwillison.net/"
