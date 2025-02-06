-- [[file:../../../examples/51-sqlite-queries.org::*Total Token Usage and Estimated Cost][Total Token Usage and Estimated Cost:1]]
WITH model_costs AS (
  SELECT model,
         SUM(input_tokens) as total_input_tokens,
         SUM(output_tokens) as total_output_tokens,
         -- Approximate costs (modify according to actual pricing)
         CASE 
           WHEN model LIKE '%gpt-4%' THEN 0.03
           WHEN model LIKE '%gpt-3.5%' THEN 0.002
           ELSE 0.01
         END as input_cost_per_1k,
         CASE 
           WHEN model LIKE '%gpt-4%' THEN 0.06
           WHEN model LIKE '%gpt-3.5%' THEN 0.002
           ELSE 0.03
         END as output_cost_per_1k
  FROM responses
  GROUP BY model
)
SELECT 
  model,
  total_input_tokens,
  total_output_tokens,
  ROUND((total_input_tokens * input_cost_per_1k / 1000.0) +
        (total_output_tokens * output_cost_per_1k / 1000.0), 2) as estimated_cost_usd,
  ROUND((total_input_tokens + total_output_tokens) / 1000.0, 1) as total_tokens_k
FROM model_costs
ORDER BY estimated_cost_usd DESC;
-- Total Token Usage and Estimated Cost:1 ends here
