-- [[file:../../../examples/51-sqlite-queries.org::*Token Usage Trends][Token Usage Trends:1]]
SELECT DATE(r.datetime_utc) as date,
       COUNT(DISTINCT r.conversation_id) as conversations,
       SUM(r.input_tokens) as total_input_tokens,
       SUM(r.output_tokens) as total_output_tokens,
       ROUND(AVG(r.duration_ms), 2) as avg_response_time
FROM responses r
GROUP BY date
ORDER BY date DESC
LIMIT 7;
-- Token Usage Trends:1 ends here
