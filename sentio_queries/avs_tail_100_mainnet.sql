SELECT *
FROM mev_commit_avs
WHERE chain = '1'
ORDER BY timestamp DESC
LIMIT 100
