# Chat With Your Database Demo

This demo shows how to use LLM tools to create a natural language interface to a SQLite database. It demonstrates the new tool support in LLM 0.26a0, as discussed in Simon Willison's [PyCon 2025 workshop](https://building-with-llms-pycon-2025.readthedocs.io/en/latest/tools.html#tools).

## How It Works

1. The script creates a sample SQLite database with customers and orders tables
2. It provides an `execute_sql()` tool function that the LLM can call to run SQL queries
3. The system prompt contains the database schema and instructions
4. The user can ask questions in natural language
5. The LLM translates these questions into SQL, executes them, and explains the results

## Running the Demo

```bash
# Activate your virtual environment
source .venv/bin/activate

# Run the script
uv run python examples/chat_with_database.py
```

## Example Questions

Try asking questions like:

- "How many customers do we have?"
- "What's the total amount spent by each customer?"
- "Who ordered a laptop and when?"
- "What was our highest value order?"

## Implementation Details

The core of this demo is the `execute_sql()` tool function:

```python
def execute_sql(sql: str):
    """
    Tool for the LLM: run arbitrary SQL against the SQLite DB
    and return the rows as a list of dicts.
    """
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute(sql)
        rows = cursor.fetchall()
        
        # Convert rows to list of dicts
        result = [dict(row) for row in rows]
        
        conn.close()
        return result
    except Exception as e:
        return {"error": str(e)}
```

This function:
1. Takes a SQL query string as input
2. Connects to the SQLite database
3. Executes the query
4. Returns the results as a list of dictionaries
5. Handles errors gracefully

The LLM uses this tool to translate natural language questions into SQL and execute them:

```python
response = model.chain(
    user_input,
    system=system_prompt,
    tools=[execute_sql],
    reasoning_effort="high"
)
```

## Customization Options

You can customize this demo by:
- Changing the database schema and data
- Modifying the system prompt for different behaviors
- Adding additional tools for more capabilities
- Connecting to different database engines