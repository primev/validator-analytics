WITH distinct_pubkey AS (
    -- For each pubkey, find its single most recent block_number
    SELECT
      valBLSPubKey,
      block_number,
      ROW_NUMBER() OVER (
        PARTITION BY valBLSPubKey
        ORDER BY block_number DESC
      ) AS rn
    FROM vanilla_registry_staking
    WHERE chain = '17000'
      AND eventType IN ('Staked','StakeAdded')
),
latest_pubkey AS (
    -- Keep only the most recent row (rn = 1) for each pubkey
    SELECT valBLSPubKey, block_number
    FROM distinct_pubkey
    WHERE rn = 1
),
ranked_pubkey AS (
    -- Rank these pubkeys by descending block_number
    SELECT
      valBLSPubKey,
      block_number,
      ROW_NUMBER() OVER (ORDER BY block_number DESC) AS rank_pub
    FROM latest_pubkey
),
top_100_pubkey AS (
    -- Limit to the top 100 distinct pubkeys
    SELECT valBLSPubKey, rank_pub
    FROM ranked_pubkey
    WHERE rank_pub <= 100
),
----------------------------------------------------------------
distinct_staker AS (
    -- For each staking account (msgSender), find its single most recent block_number
    SELECT
      msgSender,
      block_number,
      ROW_NUMBER() OVER (
        PARTITION BY msgSender
        ORDER BY block_number DESC
      ) AS rn
    FROM vanilla_registry_staking
    WHERE chain = '17000'
      AND eventType IN ('Staked','StakeAdded')
),
latest_staker AS (
    SELECT msgSender, block_number
    FROM distinct_staker
    WHERE rn = 1
),
ranked_staker AS (
    SELECT
      msgSender,
      block_number,
      ROW_NUMBER() OVER (ORDER BY block_number DESC) AS rank_st
    FROM latest_staker
),
top_100_staker AS (
    SELECT msgSender, rank_st
    FROM ranked_staker
    WHERE rank_st <= 100
)
SELECT
    tp.valBLSPubKey AS tail_100_pubkeys,
    ts.msgSender    AS tail_100_stakers
FROM top_100_pubkey tp
FULL JOIN top_100_staker ts 
  ON tp.rank_pub = ts.rank_st
ORDER BY COALESCE(tp.rank_pub, ts.rank_st)
