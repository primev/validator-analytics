WITH operator_agg AS (
    /* 1) Aggregate each operator's earliest register/deregister dates */
    SELECT
        operator,
        MIN(CASE WHEN eventType = 'OperatorRegistered'
                 THEN toDate(timestamp) END) AS earliest_op_reg,
        MIN(CASE WHEN eventType IN ('OperatorDeregistrationRequested','OperatorDeregistered')
                 THEN toDate(timestamp) END) AS earliest_op_dereg
    FROM mev_commit_avs
    WHERE chain = '1'
    GROUP BY operator
),
validator_agg AS (
    /* 2) Aggregate each validator's earliest register/deregister dates */
    SELECT
        validatorPubKey,
        MIN(CASE WHEN eventType = 'ValidatorRegistered'
                 THEN toDate(timestamp) END) AS earliest_val_reg,
        MIN(CASE WHEN eventType IN ('ValidatorDeregistrationRequested','ValidatorDeregistered')
                 THEN toDate(timestamp) END) AS earliest_val_dereg
    FROM mev_commit_avs
    WHERE chain = '1'
    GROUP BY validatorPubKey
),
validator_pod_agg AS (
    /* 3) For unique pod owners, track earliest register/deregister per (validatorPubKey, podOwner) */
    SELECT
        validatorPubKey,
        podOwner,
        MIN(CASE WHEN eventType = 'ValidatorRegistered'
                 THEN toDate(timestamp) END) AS earliest_val_reg,
        MIN(CASE WHEN eventType IN ('ValidatorDeregistrationRequested','ValidatorDeregistered')
                 THEN toDate(timestamp) END) AS earliest_val_dereg
    FROM mev_commit_avs
    WHERE chain = '1'
      AND podOwner IS NOT NULL
      AND podOwner <> ''
    GROUP BY validatorPubKey, podOwner
),
days AS (
    /* 4) All distinct days present in mev_commit_avs for chain=17000 */
    SELECT DISTINCT toDate(timestamp) AS day
    FROM mev_commit_avs
    WHERE chain = '1'
),
daily_operators AS (
    /* 5) Cross-join days with operator_agg to compute daily operator counts */
    SELECT
        d.day,
        SUM(
            CASE 
              WHEN oa.earliest_op_reg <= d.day
                   AND (oa.earliest_op_dereg IS NULL OR oa.earliest_op_dereg > d.day)
              THEN 1 ELSE 0 
            END
        ) AS registered_operators,
        SUM(
            CASE 
              WHEN oa.earliest_op_reg <= d.day
                   AND oa.earliest_op_dereg <= d.day
              THEN 1 ELSE 0
            END
        ) AS once_registered_operators
    FROM days d
    CROSS JOIN operator_agg oa
    GROUP BY d.day
),
daily_validators AS (
    /* 6) Cross-join days with validator_agg to compute daily validator counts.
          We'll also compute how many have dereg'd. */
    SELECT
        d.day,
        SUM(
            CASE
              WHEN va.earliest_val_reg <= d.day
                   AND (va.earliest_val_dereg IS NULL OR va.earliest_val_dereg > d.day)
              THEN 1 ELSE 0
            END
        ) AS total_registered_validators,
        SUM(
            CASE
              WHEN va.earliest_val_reg <= d.day
                   AND va.earliest_val_dereg <= d.day
              THEN 1 ELSE 0
            END
        ) AS once_registered_validators
    FROM days d
    CROSS JOIN validator_agg va
    GROUP BY d.day
),
daily_pod_owners AS (
    /* 7) Cross-join days with validator_pod_agg to find how many distinct podOwners 
          remain active. We'll group by day, counting distinct 'podOwner' only if 
          earliest_val_reg <= day AND earliest_val_dereg IS NULL or > day. */
    SELECT
        d.day,
        COUNT(DISTINCT CASE 
          WHEN vpa.earliest_val_reg <= d.day
               AND (vpa.earliest_val_dereg IS NULL OR vpa.earliest_val_dereg > d.day)
          THEN vpa.podOwner
        END) AS unique_pod_owners
    FROM days d
    CROSS JOIN validator_pod_agg vpa
    GROUP BY d.day
)
SELECT
    dops.day,
    dops.registered_operators,
    dops.once_registered_operators,
    dvals.total_registered_validators,
    dpod.unique_pod_owners,

    /* total_restaked_in_wei = 32ETH in wei * still-registered validators */
    (32000000000000000000 * dvals.total_registered_validators) AS total_restaked_in_wei,

    dvals.once_registered_validators
FROM daily_operators dops
JOIN daily_validators dvals ON dops.day = dvals.day
JOIN daily_pod_owners dpod ON dops.day = dpod.day
ORDER BY dops.day;
