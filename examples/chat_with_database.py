#!/usr/bin/env python
"""
Chat with your database example - quick demo
Based on Simon Willison's PyCon 2025 workshop materials

This script creates a simple chat interface where users can ask questions about a database
in natural language. It uses an LLM to translate those questions into SQL queries and 
then executes them against a SQLite database.
"""

import json
import os
import sqlite3
import sys
import llm

# Use a sample database or create one if it doesn't exist
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sample_database.db")

def setup_sample_database():
    """Create a sample database with some tables and data if it doesn't exist"""
    if os.path.exists(DB_PATH):
        return
    
    print("Creating sample database...")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Create tables
    cursor.execute('''
    CREATE TABLE customers (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        signup_date TEXT
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE orders (
        id INTEGER PRIMARY KEY,
        customer_id INTEGER,
        product TEXT NOT NULL,
        amount REAL NOT NULL,
        order_date TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
    )
    ''')
    
    # Insert sample data
    cursor.executemany(
        "INSERT INTO customers (name, email, signup_date) VALUES (?, ?, ?)",
        [
            ("Alice Smith", "alice@example.com", "2024-01-15"),
            ("Bob Jones", "bob@example.com", "2024-02-20"),
            ("Charlie Brown", "charlie@example.com", "2024-03-05"),
            ("Diana Prince", "diana@example.com", "2024-04-10"),
        ]
    )
    
    cursor.executemany(
        "INSERT INTO orders (customer_id, product, amount, order_date) VALUES (?, ?, ?, ?)",
        [
            (1, "Laptop", 1299.99, "2024-01-20"),
            (1, "Mouse", 25.99, "2024-01-20"),
            (2, "Keyboard", 89.99, "2024-02-25"),
            (3, "Monitor", 349.99, "2024-03-10"),
            (4, "Headphones", 159.99, "2024-04-15"),
            (1, "Phone", 899.99, "2024-04-30"),
        ]
    )
    
    conn.commit()
    conn.close()
    print("Sample database created!")

def get_schema():
    """Get the schema of all tables in the database"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get list of tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    
    schema = []
    for table in tables:
        table_name = table[0]
        cursor.execute(f"PRAGMA table_info({table_name})")
        columns = cursor.fetchall()
        
        schema.append(f"Table: {table_name}")
        for col in columns:
            schema.append(f"  - {col[1]} ({col[2]})")
    
    conn.close()
    return "\n".join(schema)

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

def pretty_print_json(data):
    """Print JSON data in a readable format"""
    print(json.dumps(data, indent=2, default=str))

def main():
    setup_sample_database()
    
    # Get database schema for the system prompt
    schema = get_schema()
    
    system_prompt = f"""
    You are a helpful assistant that helps users query a SQLite database.
    
    The database has the following schema:
    
    {schema}
    
    When users ask questions about the data, you should:
    1. Translate their question into a SQL query
    2. Use the execute_sql tool to run that query
    3. Explain the results in a helpful way
    
    If the query fails, explain why and suggest a corrected query.
    Always show the SQL you're executing to the user.
    """
    
    # Get available model
    try:
        model = llm.get_model("o4-mini")
    except Exception:
        print("Model o4-mini not available, using default model")
        model = llm.get_model()
    
    print("\nWelcome to the database chat interface!")
    print("Ask questions about the customers and orders in the database.")
    print("Type 'exit' or 'quit' to end the session.\n")
    
    while True:
        # Get user input
        try:
            user_input = input("\nYour question: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nExiting...")
            break
        
        if user_input.lower() in ('exit', 'quit', 'q'):
            print("Exiting...")
            break
        
        if not user_input:
            continue
        
        try:
            print("\nThinking...")
            
            # Send the question to the LLM with the execute_sql tool
            response = model.chain(
                user_input,
                system=system_prompt,
                tools=[execute_sql],
                reasoning_effort="high"
            )
            
            result = response.text().strip()
            print(f"\n{result}")
            
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    main()