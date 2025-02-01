llm -m codellama -t memory-agent "New task discussed: Implement authentication system" | \
  tee ../data/memory-codellama-auth.md | head -n 5
