llm -m "anthropic/claude-3-5-sonnet-20241022" -t reflection-agent "Morning session focused on auth system design choices" | \
  tee ../data/reflection-claude-auth.md | head -n 5
