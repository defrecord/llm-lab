-- [[file:../../../examples/51-sqlite-queries.org::*Conversations by Date][Conversations by Date:1]]
SELECT DATE(created, 'unixepoch') as date,
       COUNT(*) as conversation_count
FROM conversations
GROUP BY date
ORDER BY date DESC
LIMIT 10;
-- Conversations by Date:1 ends here
