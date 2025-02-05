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

# Help pattern - any line starting with "##"
.DEFAULT_GOAL := help
help:  ## Display this help
        @grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
        awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'

.PHONY: test clean check run all format lint pytest docs layout register-templates

# Core setup and usage
all: clean init check check-env llm-model-default run ## Run complete setup process

init: $(INIT_MARKER) docs ## [Core] Set up your environment
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


check-set: check-env ./scripts/set-providers.sh  ## [Config] Set up LLM providers
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
        @./scripts/run-without-emacs.sh

# Development and testing
sanity: scripts/sanity.sh ## [Dev] Run comprehensive sanity checks with multi-model analysis
        @echo "Running sanity checks..."
        @mkdir -p data/sanity
        @echo "Testing init..." && make init 2>&1 | tee data/sanity/init.log
        @echo "Testing check..." && make check 2>&1 | tee data/sanity/check.log
        @echo "Testing check-set..." && make check-set 2>&1 | tee data/sanity/check-set.log
        @echo "Testing tangle..." && make tangle 2>&1 | tee data/sanity/tangle.log
        @echo "Testing run..." && make run 2>&1 | tee data/sanity/run.log
        @echo "Pre-analyzing logs with Ollama..."
        @for log in data/sanity/*.log; do \
                echo "\nPre-analyzing $${log} with llama2..."; \
                llm -m ollama/llama2 "Review this make target output and identify key issues and patterns. Focus on errors, warnings, and potential improvements:" "$${log}" 2>&1 | tee "$${log}.pre_analysis"; \
        done
        @echo "Performing detailed analysis with Anthropic Claude..."
        @for log in data/sanity/*.log; do \
                echo "\nAnalyzing $${log}..."; \
                llm -m anthropic "Review the make target output and pre-analysis below. Provide specific, actionable recommendations for improving the Makefile target and related configuration. Focus on:\n\
                1. Error handling\n\
                2. Dependencies\n\
                3. Performance\n\
                4. User feedback\n\
                5. Resource management\n\n\
                Make Target Output:\n$$(cat $${log})\n\n\
                Llama2 Pre-analysis:\n$$(cat $${log}.pre_analysis)" 2>&1 | tee "$${log}.analysis"; \
        done
        @echo "Sanity check complete. See data/sanity/*.log.analysis for full recommendations"

install: ## [Dev] Install package in development mode
        @echo "Running Python setup..."
        @UV_SYSTEM_PYTHON=1 uv pip install -e .


test: format pytest ## [Dev] Run all tests and checks
        @echo "Running tests..."
        @UV_SYSTEM_PYTHON=1 uv run pytest $(TESTS_DIR)

pytest:
        @echo "Running pytest..."
        @UV_SYSTEM_PYTHON=1 uv run pytest $(TESTS_DIR) -v

format:
        @echo "Formatting Python code..."
        @UV_SYSTEM_PYTHON=1 uv run black $(PYTHON_SRC) $(TESTS_DIR)

lint:
        @echo "Running linters..."
        @UV_SYSTEM_PYTHON=1 uv run black --check $(PYTHON_SRC) $(TESTS_DIR)
        @UV_SYSTEM_PYTHON=1 uv run ruff check $(PYTHON_SRC) $(TESTS_DIR)

TANGLE_SCRIPT = scripts/tangle.sh
tangle: $(ORG_FILES) ## [Core] Tangle all org files
        @echo "Tangling org files..."
        @$(TANGLE_SCRIPT) $(ORG_FILES) | tee $(DATA_DIR)/tangle.log

docs: ## [Core] Process org files with emacs
        @echo "Processing org files..."
        @emacs --batch -l .emacs.d/init.el \
                --eval "(progn \
                        (require 'org) \
                        (setq org-confirm-babel-evaluate nil) \
                        (mapc (lambda (file) \
                                (message \"Processing %s\" file) \
                                (find-file file) \
                                (org-babel-execute-buffer) \
                                (save-buffer)) \
                        '($(ORG_FILES))))"

layout: ## Show directory purposes and descriptions
        @echo "Project layout:"
        @for dir in */; do \
                if [ -f "$$dir.description" ]; then \
                        printf "%-20s %s\n" "$$dir" "$$(cat $$dir.description)"; \
                else \
                        printf "%-20s %s\n" "$$dir" "No description"; \
                fi \
        done

register-templates: ## Register all templates from scripts/register-* files
        @echo "Registering all templates..."
        @./scripts/register-templates.sh

clean: ## Reset your environment if needed
        @echo "Cleaning..."
        @rm -f $(INIT_MARKER)
        @rm -f $(CONFIG_FILE)
        @rm -rf $(VENV_DIR) build dist *.egg-info **pycache** .pytest_cache data/sanity

IMAGES_DIR = $(DATA_DIR)/images
DOWNLOAD_SCRIPT = scripts/download-jwalsh-photos.sh
EMBEDDINGS_ORG = examples/04-embeddings.org

$(IMAGES_DIR): $(DOWNLOAD_SCRIPT)
                                   @$(DOWNLOAD_SCRIPT)

$(EMBEDDINGS_ORG): $(IMAGES_DIR) $(TANGLE_SCRIPT)
         @$(TANGLE_SCRIPT) $(EMBEDDINGS_ORG) | tee $(DATA_DIR)/tangle-embeddings.log


embeddings: $(EMBEDDINGS_ORG) scripts/photo-semantics.sh ## [Advanced] Try vector embeddings with image semantic analysis
        @$(TANGLE_SCRIPT) $(EMBEDDINGS_ORG) | tee $(DATA_DIR)/tangle-embeddings.log

check-coverage: scripts/check-llm-coverage.sh ## [Advanced] Analyze LLM command coverage
        @echo "Analyzing LLM command coverage..."
        @./scripts/check-llm-coverage.sh
        @echo "Coverage report available in data/spider/simonwillison.net/"

analyze-posts: scripts/analyze-llm-posts.sh ## [Advanced] Study LLM usage patterns
        @echo "Analyzing LLM posts from simonwillison.net..."
        @./scripts/analyze-llm-posts.sh
        @echo "Analysis complete. Reports available in data/spider/simonwillison.net/"

# SIN Framework targets
SIN_INPUT_FILE = $(SIN_DIR)/input.txt
SIN_FRAMEWORK_FILE = $(SIN_DIR)/framework.txt
SIN_EXECUTION_PLAN = $(SIN_DIR)/execution_plan.txt
SIN_ANALYSIS_OUTPUT = $(SIN_DIR)/sin_analysis.txt

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
        @uv run files-to-prompt Makefile README.org examples scripts src | llm -c -t session-agent
        @$(LLM) chat -c -t session-agent

guides: scripts/generate-guides.sh ## [Core] Generate and process documentation guides
        @echo "Generating and processing guides..."
        @./scripts/generate-guides.sh

verify-guides: scripts/verify-guides.sh ## [Core] Verify guide format and content
        @echo "Verifying guides..."
        @./scripts/verify-guides.sh

analyze-guides: scripts/analyze-guide-responses.sh ## [Core] Analyze guide responses and generate quality report
        @echo "Analyzing guide responses..."
        @./scripts/analyze-guide-responses.sh
