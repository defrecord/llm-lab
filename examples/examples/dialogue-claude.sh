llm -m "anthropic/claude-3-5-sonnet-20241022" -t dialogue-agent "Let's discuss the authentication system implementation approach" | \
  tee ../data/dialogue-claude-auth.md | head -n 5
