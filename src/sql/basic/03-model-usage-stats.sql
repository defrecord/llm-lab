-- [[file:../../../examples/51-sqlite-queries.org::*Model Usage Statistics][Model Usage Statistics:1]]
SELECT model,
       COUNT(*) as usage_count,
       ROUND(AVG(prompt_tokens), 2) as avg_prompt_tokens,
       ROUND(AVG(completion_tokens), 2) as avg_completion_tokens
FROM conversation_responses
GROUP BY model
ORDER BY usage_count DESC;
-- Model Usage Statistics:1 ends here
