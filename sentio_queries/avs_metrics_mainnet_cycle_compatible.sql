WITH
days AS (
    SELECT DISTINCT toDate(timestamp) AS day
    FROM mev_commit_avs
    WHERE chain = '1'
),

op_entities AS (
    SELECT DISTINCT operator
    FROM mev_commit_avs
    WHERE chain = '1'
      AND operator IS NOT NULL
      AND operator <> ''
),
op_deltas AS (
    SELECT
        operator,
        toDate(timestamp) AS day,
        SUM(CASE WHEN eventType = 'OperatorRegistered' THEN 1 ELSE 0 END) AS reg_delta,
        SUM(CASE WHEN eventType = 'OperatorDeregistrationRequested' THEN 1 ELSE 0 END) AS dereg_req_delta,
        SUM(CASE WHEN eventType = 'OperatorDeregistered' THEN 1 ELSE 0 END) AS dereg_delta
    FROM mev_commit_avs
    WHERE chain = '1'
      AND operator IS NOT NULL
      AND operator <> ''
    GROUP BY operator, toDate(timestamp)
),
op_grid AS (
    SELECT d.day, e.operator
    FROM days d
    CROSS JOIN op_entities e
),
op_state AS (
    SELECT
        g.day,
        g.operator,
        SUM(COALESCE(d.reg_delta, 0) - COALESCE(d.dereg_delta, 0)) OVER (
            PARTITION BY g.operator ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS active_count,
        SUM(COALESCE(d.reg_delta, 0)) OVER (PARTITION BY g.operator ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_regs,
        SUM(COALESCE(d.dereg_req_delta, 0)) OVER (PARTITION BY g.operator ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_dereg_reqs,
        SUM(COALESCE(d.dereg_delta, 0)) OVER (PARTITION BY g.operator ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_deregs
    FROM op_grid g
    LEFT JOIN op_deltas d
      ON d.operator = g.operator AND d.day = g.day
),
daily_operators AS (
    SELECT
        day,
        SUM(active_count > 0) AS current_registered_operators,
        SUM(cum_deregs > 0) AS operators_ever_deregistered
    FROM op_state
    GROUP BY day
),

val_entities AS (
    SELECT DISTINCT validatorPubKey
    FROM mev_commit_avs
    WHERE chain = '1'
      AND validatorPubKey IS NOT NULL
      AND validatorPubKey <> ''
),
val_deltas AS (
    SELECT
        validatorPubKey,
        toDate(timestamp) AS day,
        SUM(CASE WHEN eventType = 'ValidatorRegistered' THEN 1 ELSE 0 END) AS reg_delta,
        SUM(CASE WHEN eventType = 'ValidatorDeregistrationRequested' THEN 1 ELSE 0 END) AS dereg_req_delta,
        SUM(CASE WHEN eventType = 'ValidatorDeregistered' THEN 1 ELSE 0 END) AS dereg_delta
    FROM mev_commit_avs
    WHERE chain = '1'
      AND validatorPubKey IS NOT NULL
      AND validatorPubKey <> ''
    GROUP BY validatorPubKey, toDate(timestamp)
),
val_grid AS (
    SELECT d.day, e.validatorPubKey
    FROM days d
    CROSS JOIN val_entities e
),
val_state AS (
    SELECT
        g.day,
        g.validatorPubKey,
        /* Only final dereg deactivates */
        SUM(COALESCE(d.reg_delta, 0) - COALESCE(d.dereg_delta, 0)) OVER (
            PARTITION BY g.validatorPubKey ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS active_count,
        SUM(COALESCE(d.reg_delta, 0)) OVER (PARTITION BY g.validatorPubKey ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_regs,
        SUM(COALESCE(d.dereg_req_delta, 0)) OVER (PARTITION BY g.validatorPubKey ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_dereg_reqs,
        SUM(COALESCE(d.dereg_delta, 0)) OVER (PARTITION BY g.validatorPubKey ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_deregs
    FROM val_grid g
    LEFT JOIN val_deltas d
      ON d.validatorPubKey = g.validatorPubKey AND d.day = g.day
),
daily_validators AS (
    SELECT
        day,
        SUM(active_count > 0) AS total_registered_validators,
        SUM(cum_regs) AS total_validator_reg_events,
        SUM(cum_dereg_reqs) AS total_validator_dereg_request_events,
        SUM(cum_deregs) AS total_validator_dereg_events,
        SUM(cum_deregs > 0) AS validators_ever_deregistered
    FROM val_state
    GROUP BY day
),

vpair_entities AS (
    SELECT DISTINCT validatorPubKey, podOwner
    FROM mev_commit_avs
    WHERE chain = '1'
      AND validatorPubKey IS NOT NULL AND validatorPubKey <> ''
      AND podOwner IS NOT NULL AND podOwner <> ''
),
vpair_deltas AS (
    SELECT
        validatorPubKey,
        podOwner,
        toDate(timestamp) AS day,
        SUM(CASE WHEN eventType = 'ValidatorRegistered' THEN 1 ELSE 0 END) AS reg_delta,
        SUM(CASE WHEN eventType = 'ValidatorDeregistrationRequested' THEN 1 ELSE 0 END) AS dereg_req_delta,
        SUM(CASE WHEN eventType = 'ValidatorDeregistered' THEN 1 ELSE 0 END) AS dereg_delta
    FROM mev_commit_avs
    WHERE chain = '1'
      AND validatorPubKey IS NOT NULL AND validatorPubKey <> ''
      AND podOwner IS NOT NULL AND podOwner <> ''
      AND eventType IN ('ValidatorRegistered','ValidatorDeregistrationRequested','ValidatorDeregistered')
    GROUP BY validatorPubKey, podOwner, toDate(timestamp)
),
vpair_grid AS (
    SELECT d.day, e.validatorPubKey, e.podOwner
    FROM days d
    CROSS JOIN vpair_entities e
),
vpair_state AS (
    SELECT
        g.day,
        g.validatorPubKey,
        g.podOwner,
        SUM(COALESCE(d.reg_delta, 0) - COALESCE(d.dereg_delta, 0)) OVER (
            PARTITION BY g.validatorPubKey, g.podOwner ORDER BY g.day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS active_count
    FROM vpair_grid g
    LEFT JOIN vpair_deltas d
      ON d.validatorPubKey = g.validatorPubKey
     AND d.podOwner = g.podOwner
     AND d.day = g.day
),
daily_pod_owners AS (
    SELECT
        day,
        COUNT(DISTINCT CASE WHEN active_count > 0 THEN podOwner END) AS current_unique_pod_owners
    FROM vpair_state
    GROUP BY day
)

SELECT
    dops.day,
    dops.current_registered_operators,
    dops.operators_ever_deregistered,
    dvals.total_registered_validators,
    dpod.current_unique_pod_owners,
    (32000000000000000000 * dvals.total_registered_validators) AS total_restaked_in_wei,
    dvals.validators_ever_deregistered,
    dvals.total_validator_reg_events,
    dvals.total_validator_dereg_request_events,
    dvals.total_validator_dereg_events
FROM daily_operators dops
JOIN daily_validators dvals ON dops.day = dvals.day
JOIN daily_pod_owners dpod ON dops.day = dpod.day
ORDER BY dops.day;
