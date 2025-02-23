WITH 
----------------------------------------------------------------
-- Vault Addresses: currently registered (no dereg) + deduplicated
vault_distinct AS (
    SELECT
      vault,
      block_number,
      ROW_NUMBER() OVER (
        PARTITION BY vault
        ORDER BY block_number DESC
      ) AS rn
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'VaultRegistered'
      AND vault NOT IN (
         SELECT vault
         FROM mev_commit_middleware
         WHERE chain = '17000'
           AND eventType IN ('VaultDeregistrationRequested', 'VaultDeregistered')
      )
),
vault_latest AS (
    SELECT vault, block_number
    FROM vault_distinct
    WHERE rn = 1  -- newest row per vault
),
vault_ranked AS (
    SELECT
      vault,
      block_number,
      ROW_NUMBER() OVER (ORDER BY block_number DESC) AS row_rank
    FROM vault_latest
),
top_100_vault AS (
    SELECT vault, block_number
    FROM vault_ranked
    WHERE row_rank <= 100
),
----------------------------------------------------------------
-- Operators: currently registered + deduplicated
op_distinct AS (
    SELECT
      operator,
      block_number,
      ROW_NUMBER() OVER (
        PARTITION BY operator
        ORDER BY block_number DESC
      ) AS rn
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'OperatorRegistered'
      AND operator NOT IN (
         SELECT operator
         FROM mev_commit_middleware
         WHERE chain = '17000'
           AND eventType IN ('OperatorDeregistrationRequested', 'OperatorDeregistered')
      )
),
op_latest AS (
    SELECT operator, block_number
    FROM op_distinct
    WHERE rn = 1
),
op_ranked AS (
    SELECT
      operator,
      block_number,
      ROW_NUMBER() OVER (ORDER BY block_number DESC) AS row_rank
    FROM op_latest
),
top_100_op AS (
    SELECT operator, block_number
    FROM op_ranked
    WHERE row_rank <= 100
),
----------------------------------------------------------------
-- Validator Pubkeys: currently registered + deduplicated (using blsPubkey)
val_distinct AS (
    SELECT
      blsPubkey,
      block_number,
      ROW_NUMBER() OVER (
        PARTITION BY blsPubkey
        ORDER BY block_number DESC
      ) AS rn
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'ValRecordAdded'
      AND blsPubkey NOT IN (
         SELECT blsPubkey
         FROM mev_commit_middleware
         WHERE chain = '17000'
           AND eventType IN ('ValidatorDeregistrationRequested','ValRecordDeleted')
      )
),
val_latest AS (
    SELECT blsPubkey, block_number
    FROM val_distinct
    WHERE rn = 1
),
val_ranked AS (
    SELECT
      blsPubkey,
      block_number,
      ROW_NUMBER() OVER (ORDER BY block_number DESC) AS row_rank
    FROM val_latest
),
top_100_val AS (
    SELECT blsPubkey, block_number
    FROM val_ranked
    WHERE row_rank <= 100
),
----------------------------------------------------------------
-- UNION the three sets in a subquery, including the block_number as a sort key
unioned AS (
    SELECT
      'vault' AS category,
      vault AS entity,
      block_number AS sort_key
    FROM top_100_vault
    UNION ALL
    SELECT
      'operator' AS category,
      operator AS entity,
      block_number AS sort_key
    FROM top_100_op
    UNION ALL
    SELECT
      'validator' AS category,
      blsPubkey AS entity,
      block_number AS sort_key
    FROM top_100_val
)
-- Outer query: select only the category and entity columns and order them.
SELECT 
    category,
    entity
FROM unioned
ORDER BY
    CASE category
      WHEN 'vault' THEN 1
      WHEN 'operator' THEN 2
      WHEN 'validator' THEN 3
    END,
    sort_key DESC
