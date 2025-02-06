-- [[file:../../../examples/51-sqlite-queries.org::*Conversation Patterns][Conversation Patterns:1]]
WITH ConversationStats AS (
  SELECT 
    c.id as conversation_id,
    c.name as conversation_name,
    c.model as initial_model,
    COUNT(r.id) as num_responses,
    MIN(r.datetime_utc) as start_time,
    MAX(r.datetime_utc) as end_time,
    SUM(r.input_tokens) as total_input_tokens,
    SUM(r.output_tokens) as total_output_tokens,
    SUM(r.duration_ms) as total_duration_ms
  FROM conversations c
  LEFT JOIN responses r ON c.id = r.conversation_id
  GROUP BY c.id
)
SELECT 
  ROUND(AVG(num_responses), 1) as avg_responses_per_conversation,
  ROUND(AVG(total_input_tokens), 0) as avg_input_tokens_per_conversation,
  ROUND(AVG(total_output_tokens), 0) as avg_output_tokens_per_conversation,
  ROUND(AVG(total_duration_ms) / 1000.0, 1) as avg_conversation_duration_sec,
  COUNT(*) as total_conversations,
  SUM(num_responses) as total_responses
FROM ConversationStats;
-- Conversation Patterns:1 ends here
