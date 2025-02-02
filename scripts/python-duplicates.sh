# Install Symbex if not already installed
pip install symbex

# Extract and embed Python code
find . -name '*.py' | \
  xargs -I {} symbex '*' '*:*' --nl --file {} | \
  llm embed-multi python-code - \
    --model sentence-transformers/TaylorAI/gte-tiny \
    --format nl \
    --store

llm similar python-code -c 'duplicate function' | jq .id

