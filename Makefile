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

test: ## Run test suite
	@echo "Running tests..."
	@pytest tests/

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
		--kill
