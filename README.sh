llm -m gemini-1.5-pro-latest "Write a hello world function in uiua" 2>&1 | \
 tee data/test.log | head -n 5

llm logs -c --json | jq '.[]|.duration_ms, .input_tokens, .output_tokens' 2>&1 | \
 tee data/metrics.json | head -n 5
