WITH val_agg AS (
    SELECT
        valBLSPubKey,
        -- Earliest day of any Staked/StakeAdded event
        MIN(CASE WHEN eventType IN ('Staked', 'StakeAdded')
                 THEN toDate(timestamp) END) AS earliest_stake_day,
        -- Earliest day of any Unstaked/StakeWithdrawn event (NULL if never unstaked)
        MIN(CASE WHEN eventType IN ('Unstaked', 'StakeWithdrawn')
                 THEN toDate(timestamp) END) AS earliest_unstake_day,
        -- Sum of amounts for Staked + StakeAdded
        SUM(CASE WHEN eventType IN ('Staked', 'StakeAdded')
                 THEN amount ELSE 0 END) AS total_staked
    FROM vanilla_registry_staking
    WHERE chain = '1'
    GROUP BY valBLSPubKey
),
val_staker_agg AS (
    SELECT
        valBLSPubKey,
        from_address,
        -- Earliest day this (valBLSPubKey, from_address) performed a stake
        MIN(CASE WHEN eventType IN ('Staked', 'StakeAdded')
                 THEN toDate(timestamp) END) AS earliest_stake_day,
        -- Earliest day they performed an unstake, if any
        MIN(CASE WHEN eventType IN ('Unstaked', 'StakeWithdrawn')
                 THEN toDate(timestamp) END) AS earliest_unstake_day
    FROM vanilla_registry_staking
    WHERE chain = '1'
    GROUP BY valBLSPubKey, from_address
),
days AS (
    -- All distinct calendar days in the dataset for chain=17000
    SELECT DISTINCT toDate(timestamp) AS day
    FROM vanilla_registry_staking
    WHERE chain = '1'
),
daily_val_metrics AS (
    -- Cross-join each day with each validator's aggregate data 
    -- and compute daily counts/sums.
    SELECT
        d.day,
        -- (1) total_registered_validators
        SUM(
          CASE 
            WHEN va.earliest_stake_day <= d.day
                 AND (va.earliest_unstake_day IS NULL OR va.earliest_unstake_day > d.day)
            THEN 1 
            ELSE 0 
          END
        ) AS total_registered_validators,

        -- (2) total_staked_amount
        SUM(
          CASE 
            WHEN va.earliest_stake_day <= d.day
                 AND (va.earliest_unstake_day IS NULL OR va.earliest_unstake_day > d.day)
            THEN va.total_staked 
            ELSE 0 
          END
        ) AS total_staked_amount,

        -- (4) staked_and_unstaked_validator_count
        SUM(
          CASE 
            WHEN va.earliest_stake_day <= d.day
                 AND va.earliest_unstake_day <= d.day
            THEN 1 
            ELSE 0 
          END
        ) AS staked_and_unstaked_validator_count

    FROM days d
    CROSS JOIN val_agg va
    GROUP BY d.day
),
daily_stakers AS (
    -- Count distinct from_address for all validators that remain active on each day
    SELECT
        d.day,
        COUNT(DISTINCT CASE
          WHEN sa.earliest_stake_day <= d.day
               AND (sa.earliest_unstake_day IS NULL OR sa.earliest_unstake_day > d.day)
          THEN sa.from_address
        END) AS unique_stakers
    FROM days d
    CROSS JOIN val_staker_agg sa
    GROUP BY d.day
)
SELECT
    dv.day,
    dv.total_registered_validators,
    dv.total_staked_amount,
    ds.unique_stakers,
    dv.staked_and_unstaked_validator_count
FROM daily_val_metrics dv
JOIN daily_stakers ds USING (day)
ORDER BY dv.day;
