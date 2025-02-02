tree -a -I '.git|.venv|__pycache__|*.pyc' . | llm -m llama3.2 -c -t memory \
  "Identify the most important files and directories in this codebase and explain their purpose."
