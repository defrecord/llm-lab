# 1. Memory agent records the task
llm -m "anthropic/claude-3-5-sonnet-20241022" -t memory-agent "New auth system design task" | \
  tee ../data/workflow-memory.md | head -n 5

# 2. Dialogue agent discusses approach
llm -m codellama -t dialogue-agent "Discuss auth system implementation strategy" | \
  tee ../data/workflow-dialogue.md | head -n 5

# 3. Reflection agent analyzes session
llm -m deepseek-r1 -t reflection-agent "Review morning auth system design session" | \
  tee ../data/workflow-reflection.md | head -n 5

# 4. Summary agent documents decisions
llm -m llama3.2 -t summary-agent "Summarize auth system design decisions and next steps" | \
  tee ../data/workflow-summary.md | head -n 5
