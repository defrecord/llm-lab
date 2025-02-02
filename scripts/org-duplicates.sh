llm embed-multi readmes \
  --model sentence-transformers/all-MiniLM-L6-v2 \
  --files . '**/**.{md,org}' \
  --store
