-- [[file:../../../examples/51-sqlite-queries.org::*Conversations by Date][Conversations by Date:1]]
SELECT DATE(r.datetime_utc) as date,
       COUNT(DISTINCT c.id) as conversation_count,
       COUNT(*) as response_count
FROM conversations c
JOIN responses r ON c.id = r.conversation_id
GROUP BY date
ORDER BY date DESC
LIMIT 10;
-- Conversations by Date:1 ends here
