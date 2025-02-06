-- [[file:../../../examples/51-sqlite-queries.org::*Full Text Search Example][Full Text Search Example:1]]
-- Example searching for specific topics in prompts and responses
SELECT r.id,
       r.model,
       r.prompt,
       r.response,
       r.datetime_utc,
       r.input_tokens + r.output_tokens as total_tokens
FROM responses r
JOIN responses_fts fts ON r.id = fts.rowid
WHERE responses_fts MATCH 'python OR javascript'
ORDER BY r.datetime_utc DESC
LIMIT 5;
-- Full Text Search Example:1 ends here
