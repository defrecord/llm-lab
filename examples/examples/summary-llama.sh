llm -m llama3.2 -t summary-agent "Show keep patterns in creating and maintaining Makefiles" | \
  tee ../data/summary-llama-makefiles.md | head -n 5
