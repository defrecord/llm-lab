# Color codes
CYAN := \033[36m
RESET := \033[0m

# Build markers and paths
VENV_DIR := .venv
INIT_MARKER := .init
CONFIG_FILE := config/model.conf
LLM := uv run llm

# Help pattern - any line starting with "##"
.DEFAULT_GOAL := help
help:  ## Display this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'

.PHONY: test clean check run all git-config

all: clean init check check-env git-config llm-model-default run ## Run all setup and initialization steps

git-config:
	@if [ -f config/git.conf ]; then \
		echo "Using git config from config/git.conf"; \
		. config/git.conf && \
		git config user.name "$$GIT_USER" && \
		git config user.email "$$GIT_EMAIL" && \
		git config --unset commit.gpgsign || true; \
	else \
		echo "Using system git config (create config/git.conf to override)"; \
	fi

init: $(INIT_MARKER) ## Initialize project (only runs once unless cleaned)

$(INIT_MARKER): $(CONFIG_FILE)
	@echo "Initializing project..."
	@test -d $(VENV_DIR) || uv venv
	@. $(VENV_DIR)/bin/activate && uv pip install -r requirements.txt
	@. $(VENV_DIR)/bin/activate && uv pip install -r dev-requirements.txt
	@$(LLM) install --upgrade llm-anthropic llm-cluster llm-sentence-transformers llm-ollama llm-gemini
	@touch $(INIT_MARKER)

$(CONFIG_FILE):
	@mkdir -p config
	@if [ ! -z "$$http_proxy" ] && curl -s localhost:11434/api/version >/dev/null 2>&1; then \
		echo "LLM_MODEL=ollama/deepseek-coder" > $(CONFIG_FILE); \
	else \
		echo "LLM_MODEL=gemini-2.0-flash-exp" > $(CONFIG_FILE); \
	fi

check: ## Check if tools are installed correctly
	@$(LLM) --version
	@uv run ttok --version
	@uv run strip-tags --version
	@uv run files-to-prompt --version

llm-model-default: $(CONFIG_FILE) ## Set default LLM model based on environment
	@cat $(CONFIG_FILE)
	@. $(CONFIG_FILE) && llm models default $$LLM_MODEL

run: llm-model-default ## Run core LLM commands
	@./scripts/run-without-emacs.sh

test: ## Run test suite
	@echo "Running tests..."
	@uv run pytest tests/

lint: ## Lint code
	@uv run black src

clean: ## Clean everything and force re-initialization
	@echo "Cleaning..."
	@rm -f $(INIT_MARKER)
	@rm -f $(CONFIG_FILE)
	@rm -rf $(VENV_DIR) build dist *.egg-info **pycache** .pytest_cache

check-env: scripts/check-env.sh $(CONFIG_FILE) ## Check environment variables
	@echo "Checking environment..."
	@./scripts/check-env.sh
	@echo "Model configuration:"
	@. $(CONFIG_FILE) && echo "Using LLM model: $$LLM_MODEL"

.PHONY: plugins-upgrade
llm-plugins-upgrade:
	@echo "Upgrading all installed LLM plugins..."
	@$(LLM) install --upgrade $$(llm plugins | jq -r '.[]|.name' | tr '\n' ' ')

emacs: ## Run Emacs
	@emacs -l .emacs.d/init.el

ORG_FILES := README.org $(wildcard examples/*.org) $(wildcard docs/*.org)

tangle: $(ORG_FILES) ## Tangle all org files
	@echo "Tangling org files..."
	@./scripts/tangle.sh $(ORG_FILES)

docs: tangle ## Generate documentation

layout: ## Show directory purposes and descriptions
	@echo "Project layout:"
	@for dir in */; do \
		if [ -f "$$dir.description" ]; then \
			printf "%-20s %s\n" "$$dir" "$$(cat $$dir.description)"; \
		else \
			printf "%-20s %s\n" "$$dir" "No description"; \
		fi \
	done

scripts/register-session-agent-template.sh: prompts/session-agent.md

session-agent: scripts/register-session-agent-template.sh ## Interactively track status
	@uv run files-to-prompt Makefile README.org examples scripts src | llm -c -t session-agent
	@$(LLM) chat -c -t session-agent


.PHONY: register-templates
register-templates: ## Register all templates from scripts/register-* files
	@echo "Registering all templates..."
	@./scripts/register-templates.sh

data/images: ## Get images for embedding examples
	@ ./scripts/download-jwalsh-photos.sh

check-coverage: scripts/check-llm-coverage.sh ## Check LLM command coverage in examples
	@echo "Analyzing LLM command coverage..."
	@./scripts/check-llm-coverage.sh
	@echo "Coverage report available in data/spider/simonwillison.net/"

analyze-posts: scripts/analyze-llm-posts.sh ## Analyze LLM usage in Simon Willison's blog posts
	@echo "Analyzing LLM posts from simonwillison.net..."
	@./scripts/analyze-llm-posts.sh
	@echo "Analysis complete. Reports available in data/spider/simonwillison.net/"
