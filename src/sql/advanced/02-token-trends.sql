-- [[file:../../../examples/51-sqlite-queries.org::*Token Usage Trends][Token Usage Trends:1]]
SELECT DATE(cr.created, 'unixepoch') as date,
       SUM(prompt_tokens) as total_prompt_tokens,
       SUM(completion_tokens) as total_completion_tokens,
       COUNT(DISTINCT c.id) as num_conversations
FROM conversation_responses cr
JOIN conversations c ON cr.conversation_id = c.id
GROUP BY date
ORDER BY date DESC
LIMIT 7;
-- Token Usage Trends:1 ends here
