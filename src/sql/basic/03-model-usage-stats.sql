-- [[file:../../../examples/51-sqlite-queries.org::*Model Usage Statistics][Model Usage Statistics:1]]
SELECT r.model,
       COUNT(*) as usage_count,
       COUNT(DISTINCT r.conversation_id) as unique_conversations,
       ROUND(AVG(r.input_tokens), 2) as avg_input_tokens,
       ROUND(AVG(r.output_tokens), 2) as avg_output_tokens
FROM responses r
GROUP BY r.model
ORDER BY usage_count DESC;
-- Model Usage Statistics:1 ends here
