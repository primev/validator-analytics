SELECT *
FROM mev_commit_middleware
WHERE chain = '1'
ORDER BY timestamp DESC
LIMIT 100
