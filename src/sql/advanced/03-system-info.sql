-- [[file:../../../examples/51-sqlite-queries.org::*System Information Analysis][System Information Analysis:1]]
SELECT key, value, COUNT(*) as occurrence_count
FROM system_info
GROUP BY key, value
ORDER BY key, occurrence_count DESC;
-- System Information Analysis:1 ends here
