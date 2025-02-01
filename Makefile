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

check-env: ## Check environment variables
	@echo "Checking environment..."
	@./scripts/check-env.sh

