-- [[file:../../../examples/51-sqlite-queries.org::*Response Time Analysis][Response Time Analysis:1]]
SELECT model,
       COUNT(*) as responses,
       ROUND(AVG(duration_ms), 2) as avg_duration_ms,
       ROUND(MIN(duration_ms), 2) as min_duration_ms,
       ROUND(MAX(duration_ms), 2) as max_duration_ms,
       ROUND(AVG(input_tokens + output_tokens), 2) as avg_total_tokens
FROM responses
GROUP BY model
ORDER BY avg_duration_ms DESC;
-- Response Time Analysis:1 ends here
