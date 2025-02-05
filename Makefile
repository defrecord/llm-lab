# Color codes
CYAN := \033[36m
RESET := \033[0m

# Build markers and paths
VENV_DIR := .venv
INIT_MARKER := .init
CONFIG_FILE := config/model.conf
LLM := uv run llm

# Python paths
PYTHON_SRC = src/llm_lab
TESTS_DIR = tests
PYTHON_FILES = $(shell find $(PYTHON_SRC) $(TESTS_DIR) -name "*.py")

# Data directories
DATA_DIR = data
SIN_DIR = $(DATA_DIR)/sin
IMAGES_DIR = $(DATA_DIR)/images
OUTPUT_DIR = $(DATA_DIR)/output
ORG_FILES := README.org $(wildcard examples/*.org) $(wildcard docs/*.org)
EMBEDDINGS_ORG = examples/04-embeddings.org
TANGLE_SCRIPT = scripts/tangle.sh
DOWNLOAD_SCRIPT = scripts/download-jwalsh-photos.sh

# SIN Framework paths
SIN_INPUT_FILE = $(SIN_DIR)/input.txt
SIN_FRAMEWORK_FILE = $(SIN_DIR)/framework.txt
SIN_EXECUTION_PLAN = $(SIN_DIR)/execution_plan.txt
SIN_ANALYSIS_OUTPUT = $(SIN_DIR)/sin_analysis.txt

# Help pattern - any line starting with "##"
.DEFAULT_GOAL := help
help:  ## Display this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'

.PHONY: test clean check run all format lint docs layout register-templates \
        help init check-env llm-model-default embeddings sin session-agent guides \
        verify-guides analyze-guides sanity check-set check-coverage analyze-posts logs

# Core setup and usage
all: clean init check-env llm-model-default check run ## Run complete setup process - follows README quickstart order

init: $(INIT_MARKER) ## [Core] Set up your environment
	@echo "Running initialization..."
	@./scripts/init.sh

check: ## [LLM] Verify LLM tools are working
	@echo "Checking LLM tools..."
	@./scripts/check-llm.sh

check-env: scripts/check-env.sh $(CONFIG_FILE) ## [Config] Verify your API keys are set
	@echo "Checking environment..."
	@./scripts/check-env.sh
	@echo "Model configuration:"
	@. $(CONFIG_FILE) && echo "Using LLM model: $$LLM_MODEL"

check-set: check-env scripts/set-providers.sh  ## [Config] Set up LLM providers
	@echo "Setting environment..."
	@./scripts/set-providers.sh

# Internal targets
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

# Configuration targets
llm-model-default: $(CONFIG_FILE) ## [LLM] Configure your default LLM model
	@cat $(CONFIG_FILE)
	@. $(CONFIG_FILE) && llm models default $$LLM_MODEL

logs: ## [LLM] View your LLM interaction history
	@llm logs on
	@llm logs status
	@llm logs

run: llm-model-default ## Run the lab exercises
	@test -f scripts/run-without-emacs.sh && ./scripts/run-without-emacs.sh

# Development and testing
sanity: scripts/sanity.sh ## [Dev] Run comprehensive sanity checks with multi-model analysis
	@test -f scripts/sanity.sh && ./scripts/sanity.sh

install: ## [Dev] Install package in development mode
	@echo "Running Python setup..."
	@UV_SYSTEM_PYTHON=1 uv pip install -e .

test: format ## [Dev] Run all tests and checks
	@echo "Running tests..."
	@UV_SYSTEM_PYTHON=1 uv run pytest $(TESTS_DIR)

format:
	@echo "Formatting Python code..."
	@UV_SYSTEM_PYTHON=1 uv run black $(PYTHON_SRC) $(TESTS_DIR)

lint:
	@echo "Running linters..."
	@UV_SYSTEM_PYTHON=1 uv run black --check $(PYTHON_SRC) $(TESTS_DIR)
	@UV_SYSTEM_PYTHON=1 uv run ruff check $(PYTHON_SRC) $(TESTS_DIR)

emacs: scripts/start-emacs.sh
	@./scripts/start-emacs.sh

tangle: $(ORG_FILES) ## [Core] Tangle all org files
	@echo "Tangling org files..."
	@test -f $(TANGLE_SCRIPT) && $(TANGLE_SCRIPT) $(ORG_FILES) | tee $(DATA_DIR)/tangle.log

docs: tangle ## [Core] Process org files with emacs (alias for tangle)

layout: scripts/show-layout.sh ## Show directory purposes and descriptions
	@test -f scripts/show-layout.sh && ./scripts/show-layout.sh

register-templates: ## Register all templates from scripts/register-* files
	@echo "Registering all templates..."
	@test -f scripts/register-templates.sh && ./scripts/register-templates.sh

clean: ## Reset your environment if needed
	@echo "Cleaning..."
	@rm -f $(INIT_MARKER)
	@rm -f $(CONFIG_FILE)
	@rm -rf $(VENV_DIR) build dist *.egg-info **pycache** .pytest_cache data/sanity

$(IMAGES_DIR):
	@test -f $(DOWNLOAD_SCRIPT) && $(DOWNLOAD_SCRIPT)

embeddings: $(EMBEDDINGS_ORG) scripts/photo-semantics.sh ## [Advanced] Try vector embeddings with image semantic analysis
	@test -f $(TANGLE_SCRIPT) && $(TANGLE_SCRIPT) $(EMBEDDINGS_ORG) | tee $(DATA_DIR)/tangle-embeddings.log
	@test -f scripts/photo-semantics.sh && ./scripts/photo-semantics.sh

check-coverage: scripts/check-llm-coverage.sh ## [Advanced] Analyze LLM command coverage
	@echo "Analyzing LLM command coverage..."
	@test -f scripts/check-llm-coverage.sh && ./scripts/check-llm-coverage.sh
	@echo "Coverage report available in data/spider/simonwillison.net/"

analyze-posts: scripts/analyze-llm-posts.sh ## [Advanced] Study LLM usage patterns
	@echo "Analyzing LLM posts from simonwillison.net..."
	@test -f scripts/analyze-llm-posts.sh && ./scripts/analyze-llm-posts.sh
	@echo "Analysis complete. Reports available in data/spider/simonwillison.net/"

# SIN Framework targets
sin: $(SIN_ANALYSIS_OUTPUT) ## [Advanced] Run Structured Insight Navigator (SIN) framework for systematic analysis with multiple LLM models

$(SIN_DIR):
	@mkdir -p $(SIN_DIR)

# Framework Selection
$(SIN_FRAMEWORK_FILE): $(SIN_INPUT_FILE) | $(SIN_DIR)
	@echo "Selecting analysis framework..."
	@llm -t sin-framework < $(SIN_INPUT_FILE) | tee >(head -n 1) > $(SIN_FRAMEWORK_FILE)

# Execution Plan
$(SIN_EXECUTION_PLAN): $(SIN_FRAMEWORK_FILE)
	@echo "Generating execution plan..."
	@llm -t sin-execution-plan < $(SIN_FRAMEWORK_FILE) | tee >(head -n 3) > $(SIN_EXECUTION_PLAN)

# Analysis Output
$(SIN_ANALYSIS_OUTPUT): $(SIN_EXECUTION_PLAN)
	@echo "Executing analysis..."
	@llm -t sin-execute-and-document < $(SIN_EXECUTION_PLAN) > $(SIN_ANALYSIS_OUTPUT)
	@echo "SIN analysis complete. Results in $(SIN_ANALYSIS_OUTPUT)"

session-agent: scripts/register-session-agent-template.sh ## [Advanced] Try interactive agent tracking
	@test -f scripts/register-session-agent-template.sh && \
	uv run files-to-prompt Makefile README.org examples scripts src | llm -c -t session-agent
	@$(LLM) chat -c -t session-agent

guides: scripts/generate-guides.sh ## [Core] Generate and process documentation guides
	@echo "Generating and processing guides..."
	@test -f scripts/generate-guides.sh && ./scripts/generate-guides.sh

verify-guides: scripts/verify-guides.sh ## [Core] Verify guide format and content
	@echo "Verifying guides..."
	@test -f scripts/verify-guides.sh && ./scripts/verify-guides.sh

analyze-guides: scripts/analyze-guide-responses.sh ## [Core] Analyze guide responses and generate quality report
	@echo "Analyzing guide responses..."
	@test -f scripts/analyze-guide-responses.sh && ./scripts/analyze-guide-responses.sh
