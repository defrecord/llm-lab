#!/bin/bash

QUERY="select substr(prompt, 0, 20), length(prompt), count(*), length(prompt) * count(*) as size 
from responses 
group by prompt 
having count(*) > 1 
order by size desc"

uv run sqlite-utils "$(llm logs path)" "$QUERY" -t
