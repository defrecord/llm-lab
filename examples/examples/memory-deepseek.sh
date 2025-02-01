llm -m deepseek-r1 -t memory-agent "New task discussed: Implement authentication system" | \
  tee ../data/memory-deepseek-auth.md | head -n 5
