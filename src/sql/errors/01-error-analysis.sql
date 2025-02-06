-- [[file:../../../examples/51-sqlite-queries.org::*Error Rate by Model][Error Rate by Model:1]]
SELECT model,
       COUNT(*) as total_responses,
       SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) as error_count,
       ROUND(CAST(SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) / 
             COUNT(*) * 100, 2) as error_rate_percent
FROM conversation_responses
GROUP BY model
ORDER BY error_rate_percent DESC;
-- Error Rate by Model:1 ends here
