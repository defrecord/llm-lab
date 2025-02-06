#!/bin/bash

DB_PATH="/home/computeruse/.config/io.datasette.llm/logs.db"

echo "=== LLM Logs Analysis ==="
echo

# 1. Basic Statistics
echo "1. Basic Statistics:"
sqlite3 "$DB_PATH" "
SELECT 
    (SELECT COUNT(*) FROM responses) as total_responses,
    (SELECT COUNT(*) FROM conversations) as total_conversations,
    (SELECT COUNT(DISTINCT model) FROM responses) as unique_models,
    ROUND(AVG(duration_ms)/1000.0, 2) as avg_duration_seconds
FROM responses;
"
echo

# 2. Model Usage Over Time
echo "2. Model Usage Timeline (Last 10 days):"
sqlite3 "$DB_PATH" "
WITH RECURSIVE dates(date) AS (
    SELECT date(MIN(datetime_utc)) FROM responses
    UNION ALL
    SELECT date(date, '+1 day')
    FROM dates
    WHERE date < date(datetime('now'))
)
SELECT 
    dates.date,
    COUNT(r.id) as requests,
    GROUP_CONCAT(DISTINCT r.model) as models_used
FROM dates 
LEFT JOIN responses r ON date(r.datetime_utc) = dates.date
GROUP BY dates.date
ORDER BY dates.date DESC
LIMIT 10;
"
echo

# 3. Token Usage Analysis
echo "3. Token Usage by Model:"
sqlite3 "$DB_PATH" "
SELECT 
    model,
    COUNT(*) as requests,
    AVG(input_tokens) as avg_input_tokens,
    AVG(output_tokens) as avg_output_tokens,
    SUM(input_tokens + output_tokens) as total_tokens,
    ROUND(AVG(duration_ms)/1000.0, 2) as avg_duration_seconds
FROM responses
WHERE model IS NOT NULL
GROUP BY model
ORDER BY requests DESC;
"
echo

# 4. Response Time Distribution
echo "4. Response Time Distribution (percentiles):"
sqlite3 "$DB_PATH" "
WITH ordered_times AS (
    SELECT 
        duration_ms,
        NTILE(4) OVER (ORDER BY duration_ms) as quartile
    FROM responses
    WHERE duration_ms IS NOT NULL
)
SELECT 
    'Q' || quartile as quartile,
    MIN(duration_ms)/1000.0 as min_seconds,
    MAX(duration_ms)/1000.0 as max_seconds,
    COUNT(*) as count
FROM ordered_times
GROUP BY quartile
ORDER BY quartile;
"
echo

# 5. Most Common Prompt Patterns
echo "5. Most Common Prompt Patterns (based on first words):"
sqlite3 "$DB_PATH" "
WITH prompt_starts AS (
    SELECT 
        SUBSTR(prompt, 1, 30) || '...' as prompt_start,
        COUNT(*) as count
    FROM responses
    GROUP BY prompt_start
    HAVING count > 1
)
SELECT * FROM prompt_starts
ORDER BY count DESC
LIMIT 5;
"
echo

# 6. Conversation Analysis
echo "6. Conversation Statistics:"
sqlite3 "$DB_PATH" "
SELECT 
    c.model as conversation_model,
    COUNT(DISTINCT c.id) as num_conversations,
    AVG(responses_per_conv.response_count) as avg_responses_per_conv,
    MAX(responses_per_conv.response_count) as max_responses_per_conv
FROM conversations c
LEFT JOIN (
    SELECT 
        conversation_id,
        COUNT(*) as response_count
    FROM responses 
    WHERE conversation_id IS NOT NULL
    GROUP BY conversation_id
) responses_per_conv ON c.id = responses_per_conv.conversation_id
WHERE c.model IS NOT NULL
GROUP BY c.model
ORDER BY num_conversations DESC;
"
echo

# 7. Full Text Search Example
echo "7. Example Responses Containing 'error' or 'failed':"
sqlite3 "$DB_PATH" "
SELECT 
    datetime_utc,
    model,
    SUBSTR(prompt, 1, 50) || '...' as prompt_preview,
    SUBSTR(response, 1, 50) || '...' as response_preview
FROM responses
WHERE response MATCH 'error OR failed'
ORDER BY datetime_utc DESC
LIMIT 3;
"
echo

# 8. System Prompt Analysis
echo "8. Most Common System Prompts:"
sqlite3 "$DB_PATH" "
SELECT 
    SUBSTR(system, 1, 50) || '...' as system_preview,
    COUNT(*) as count
FROM responses
WHERE system IS NOT NULL
GROUP BY system_preview
ORDER BY count DESC
LIMIT 5;
"
echo

# 9. Time-of-Day Analysis
echo "9. Usage by Hour of Day:"
sqlite3 "$DB_PATH" "
WITH RECURSIVE hours(hour) AS (
    SELECT 0
    UNION ALL
    SELECT hour + 1 FROM hours WHERE hour < 23
)
SELECT 
    printf('%02d:00', hours.hour) as hour_of_day,
    COUNT(r.id) as requests,
    ROUND(AVG(CASE WHEN r.id IS NOT NULL THEN r.duration_ms END)/1000.0, 2) as avg_duration_seconds
FROM hours
LEFT JOIN responses r ON strftime('%H', r.datetime_utc) = printf('%02d', hours.hour)
GROUP BY hours.hour
ORDER BY hours.hour;
"
echo

# 10. Error Rate Analysis (based on error keywords)
echo "10. Potential Error Rate Analysis:"
sqlite3 "$DB_PATH" "
SELECT
    model,
    COUNT(*) as total_requests,
    SUM(CASE WHEN response LIKE '%error%' OR response LIKE '%failed%' OR response LIKE '%exception%' THEN 1 ELSE 0 END) as error_responses,
    ROUND(100.0 * SUM(CASE WHEN response LIKE '%error%' OR response LIKE '%failed%' OR response LIKE '%exception%' THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate_percent
FROM responses
WHERE model IS NOT NULL
GROUP BY model
HAVING total_requests > 5
ORDER BY error_rate_percent DESC;
"
echo

# 11. Math Test Analysis
echo "11. Math Test Performance Analysis:"
sqlite3 "$DB_PATH" "
WITH MathTests AS (
    SELECT 
        model,
        prompt,
        CAST(TRIM(response) AS INTEGER) as response_num,
        -- Extract numbers from prompt (e.g., '5 + 3 - 2' → [5,3,2])
        CAST(REGEXP_REPLACE(prompt, 'Calculate exactly: (-?[0-9]+) \\+ (-?[0-9]+) - (-?[0-9]+).*', '\\1') AS INTEGER) as num1,
        CAST(REGEXP_REPLACE(prompt, 'Calculate exactly: (-?[0-9]+) \\+ (-?[0-9]+) - (-?[0-9]+).*', '\\2') AS INTEGER) as num2,
        CAST(REGEXP_REPLACE(prompt, 'Calculate exactly: (-?[0-9]+) \\+ (-?[0-9]+) - (-?[0-9]+).*', '\\3') AS INTEGER) as num3,
        duration_ms,
        datetime_utc
    FROM responses
    WHERE prompt LIKE 'Calculate exactly:%'
)
SELECT 
    model,
    COUNT(*) as total_tests,
    ROUND(AVG(CASE WHEN response_num = (num1 + num2 - num3) THEN 1 ELSE 0 END) * 100, 2) as accuracy_percent,
    ROUND(AVG(duration_ms), 2) as avg_duration_ms,
    MIN(duration_ms) as min_duration_ms,
    MAX(duration_ms) as max_duration_ms,
    MIN(datetime_utc) as first_test,
    MAX(datetime_utc) as last_test
FROM MathTests
GROUP BY model
ORDER BY accuracy_percent DESC, avg_duration_ms ASC;
"
echo

# 12. Recent Math Test Examples
echo "12. Recent Math Test Examples (Last 5):"
sqlite3 "$DB_PATH" "
SELECT 
    model,
    prompt as expression,
    response as answer,
    duration_ms as duration_ms,
    datetime(datetime_utc) as time
FROM responses
WHERE prompt LIKE 'Calculate exactly:%'
ORDER BY datetime_utc DESC
LIMIT 5;
"