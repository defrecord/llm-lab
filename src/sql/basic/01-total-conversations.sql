-- [[file:../../../examples/51-sqlite-queries.org::*Total Conversations Count][Total Conversations Count:1]]
SELECT COUNT(*) as total_conversations,
       COUNT(DISTINCT model) as unique_models
FROM conversations;
-- Total Conversations Count:1 ends here
