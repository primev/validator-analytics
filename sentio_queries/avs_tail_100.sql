WITH 
-- Operators: Only currently registered operators.
op_distinct AS (
  SELECT
    operator,
    block_number,
    ROW_NUMBER() OVER (
      PARTITION BY operator
      ORDER BY block_number DESC
    ) AS rn
  FROM mev_commit_avs
  WHERE chain = '17000'
    AND eventType = 'OperatorRegistered'
    AND operator NOT IN (
      SELECT operator
      FROM mev_commit_avs
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
    ROW_NUMBER() OVER (ORDER BY block_number DESC) AS rank_op
  FROM op_latest
),
top_100_op AS (
  SELECT operator, rank_op
  FROM op_ranked
  WHERE rank_op <= 100
),

-- Validator Pubkeys: Only currently registered validators.
val_distinct AS (
  SELECT
    validatorPubKey,
    block_number,
    ROW_NUMBER() OVER (
      PARTITION BY validatorPubKey
      ORDER BY block_number DESC
    ) AS rn
  FROM mev_commit_avs
  WHERE chain = '17000'
    AND eventType = 'ValidatorRegistered'
    AND validatorPubKey NOT IN (
      SELECT validatorPubKey
      FROM mev_commit_avs
      WHERE chain = '17000'
        AND eventType IN ('ValidatorDeregistrationRequested', 'ValidatorDeregistered')
    )
),
val_latest AS (
  SELECT validatorPubKey, block_number
  FROM val_distinct
  WHERE rn = 1
),
val_ranked AS (
  SELECT
    validatorPubKey,
    block_number,
    ROW_NUMBER() OVER (ORDER BY block_number DESC) AS rank_val
  FROM val_latest
),
top_100_val AS (
  SELECT validatorPubKey, rank_val
  FROM val_ranked
  WHERE rank_val <= 100
),

-- Pod Owners: Only from currently registered validators.
pod_distinct AS (
  SELECT
    podOwner,
    block_number,
    ROW_NUMBER() OVER (
      PARTITION BY podOwner
      ORDER BY block_number DESC
    ) AS rn
  FROM mev_commit_avs
  WHERE chain = '17000'
    AND eventType = 'ValidatorRegistered'
    AND podOwner IS NOT NULL
    AND podOwner <> ''
    AND validatorPubKey NOT IN (
      SELECT validatorPubKey
      FROM mev_commit_avs
      WHERE chain = '17000'
        AND eventType IN ('ValidatorDeregistrationRequested', 'ValidatorDeregistered')
    )
),
pod_latest AS (
  SELECT podOwner, block_number
  FROM pod_distinct
  WHERE rn = 1
),
pod_ranked AS (
  SELECT
    podOwner,
    block_number,
    ROW_NUMBER() OVER (ORDER BY block_number DESC) AS rank_pod
  FROM pod_latest
),
top_100_pod AS (
  SELECT podOwner, rank_pod
  FROM pod_ranked
  WHERE rank_pod <= 100
)

SELECT
  top_100_op.operator AS tail_100_operators_registered,
  top_100_val.validatorPubKey AS tail_100_validator_pubkeys_registered,
  top_100_pod.podOwner AS tail_100_pod_owners_in_val_registration
FROM top_100_op
FULL JOIN top_100_val ON top_100_op.rank_op = top_100_val.rank_val
FULL JOIN top_100_pod ON COALESCE(top_100_op.rank_op, top_100_val.rank_val) = top_100_pod.rank_pod
ORDER BY COALESCE(top_100_op.rank_op, top_100_val.rank_val, top_100_pod.rank_pod)
