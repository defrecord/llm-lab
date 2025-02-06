-- [[file:../../../examples/51-sqlite-queries.org::*Total Token Usage and Estimated Cost][Total Token Usage and Estimated Cost:1]]
WITH model_costs AS (
  SELECT model,
         SUM(prompt_tokens) as total_prompt_tokens,
         SUM(completion_tokens) as total_completion_tokens,
         -- Approximate costs (modify according to actual pricing)
         CASE 
           WHEN model LIKE '%gpt-4%' THEN 0.03
           WHEN model LIKE '%gpt-3.5%' THEN 0.002
           ELSE 0.01
         END as prompt_cost_per_1k,
         CASE 
           WHEN model LIKE '%gpt-4%' THEN 0.06
           WHEN model LIKE '%gpt-3.5%' THEN 0.002
           ELSE 0.03
         END as completion_cost_per_1k
  FROM conversation_responses
  GROUP BY model
)
SELECT 
  model,
  total_prompt_tokens,
  total_completion_tokens,
  ROUND((total_prompt_tokens * prompt_cost_per_1k / 1000.0) +
        (total_completion_tokens * completion_cost_per_1k / 1000.0), 2) as estimated_cost_usd
FROM model_costs
ORDER BY estimated_cost_usd DESC;
-- Total Token Usage and Estimated Cost:1 ends here
