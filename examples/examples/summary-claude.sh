llm -m "anthropic/claude-3-5-sonnet-20241022" -t summary-agent "Document action items from our auth system design review" | \
  tee ../data/summary-claude-auth.md | head -n 5
