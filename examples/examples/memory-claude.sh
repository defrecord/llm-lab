llm -m "anthropic/claude-3-5-sonnet-20241022" -t memory-agent "New task discussed: Implement authentication system" | \
  tee ../data/memory-claude-auth.md | head -n 5
