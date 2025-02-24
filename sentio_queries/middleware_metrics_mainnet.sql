WITH vault_agg AS (
    /* (A) Aggregate each vault's earliest registration and deregistration days */
    SELECT
        vault,
        MIN(CASE WHEN eventType = 'VaultRegistered'
                 THEN toDate(timestamp) END) AS earliest_vault_reg,
        MIN(CASE WHEN eventType IN ('VaultDeregistrationRequested','VaultDeregistered')
                 THEN toDate(timestamp) END) AS earliest_vault_dereg
    FROM mev_commit_middleware
    WHERE chain = '1'
    GROUP BY vault
),
op_agg AS (
    /* (B) Aggregate each operator's earliest registration and deregistration days */
    SELECT
        operator,
        MIN(CASE WHEN eventType = 'OperatorRegistered'
                 THEN toDate(timestamp) END) AS earliest_op_reg,
        MIN(CASE WHEN eventType IN ('OperatorDeregistrationRequested','OperatorDeregistered')
                 THEN toDate(timestamp) END) AS earliest_op_dereg
    FROM mev_commit_middleware
    WHERE chain = '1'
    GROUP BY operator
),
val_slash_agg AS (
    /* (C) For each ValRecordAdded row, join to a VaultRegistered row to get slashAmount.
       Then aggregate by blsPubkey:
         - earliest_val_add  (earliest day we see a ValRecordAdded)
         - earliest_val_dereg (earliest day of ValDeregRequested or ValRecordDeleted)
         - total_slash_amount (sum of slashAmount across all vaults in which this validator was added)
    */
    SELECT
        val.blsPubkey,
        MIN(toDate(val.timestamp)) AS earliest_val_add,
        MIN(CASE WHEN de.eventType IN ('ValidatorDeregistrationRequested','ValRecordDeleted')
                 THEN toDate(de.timestamp) END) AS earliest_val_dereg,
        SUM(vr.slashAmount) AS total_slash_amount
    FROM mev_commit_middleware val
    /* Join each ValRecordAdded to the corresponding VaultRegistered for slashAmount */
    JOIN mev_commit_middleware vr
      ON val.vault = vr.vault
     AND vr.eventType = 'VaultRegistered'
     AND vr.chain = '1'
    /* Left join to find the earliest dereg day for the same blsPubkey (if any) */
    LEFT JOIN mev_commit_middleware de
      ON de.chain = '1'
     AND de.blsPubkey = val.blsPubkey
     AND de.eventType IN ('ValidatorDeregistrationRequested','ValRecordDeleted')
    WHERE val.chain = '1'
      AND val.eventType = 'ValRecordAdded'
    GROUP BY val.blsPubkey
),
days AS (
    /* (D) All distinct days in this table (for chain=17000) */
    SELECT DISTINCT toDate(timestamp) AS day
    FROM mev_commit_middleware
    WHERE chain = '1'
),
daily_vaults AS (
    /* (E) Cross-join days × vault_agg to compute daily still/once-registered vault counts */
    SELECT
        d.day,
        SUM(
          CASE WHEN va.earliest_vault_reg <= d.day
                AND (va.earliest_vault_dereg IS NULL OR va.earliest_vault_dereg > d.day)
               THEN 1 ELSE 0 END
        ) AS still_registered_vaults,
        SUM(
          CASE WHEN va.earliest_vault_reg <= d.day
                AND va.earliest_vault_dereg <= d.day
               THEN 1 ELSE 0 END
        ) AS once_registered_vaults
    FROM days d
    CROSS JOIN vault_agg va
    GROUP BY d.day
),
daily_operators AS (
    /* (F) Cross-join days × op_agg to compute daily still/once-registered operator counts */
    SELECT
        d.day,
        SUM(
          CASE WHEN oa.earliest_op_reg <= d.day
                AND (oa.earliest_op_dereg IS NULL OR oa.earliest_op_dereg > d.day)
               THEN 1 ELSE 0 END
        ) AS still_registered_operators,
        SUM(
          CASE WHEN oa.earliest_op_reg <= d.day
                AND oa.earliest_op_dereg <= d.day
               THEN 1 ELSE 0 END
        ) AS once_registered_operators
    FROM days d
    CROSS JOIN op_agg oa
    GROUP BY d.day
),
daily_validators AS (
    /* (G) Cross-join days × val_slash_agg to compute daily validator counts + sum slash amounts
       for those STILL active on that day. We'll also count how many have once deregistered. */
    SELECT
        d.day,

        /* total_registered_validators: earliest_val_add <= day, earliest_val_dereg is NULL or > day */
        SUM(
          CASE WHEN va.earliest_val_add <= d.day
                AND (va.earliest_val_dereg IS NULL OR va.earliest_val_dereg > d.day)
               THEN 1 ELSE 0 END
        ) AS total_registered_validators,

        /* once_registered_validators: earliest_val_add <= day AND earliest_val_dereg <= day */
        SUM(
          CASE WHEN va.earliest_val_add <= d.day
                AND va.earliest_val_dereg <= d.day
               THEN 1 ELSE 0 END
        ) AS once_registered_validators,

        /* total_amount_staked: sum slashAmount for STILL-active validators on this day */
        SUM(
          CASE WHEN va.earliest_val_add <= d.day
                AND (va.earliest_val_dereg IS NULL OR va.earliest_val_dereg > d.day)
               THEN va.total_slash_amount ELSE 0 END
        ) AS total_amount_staked
    FROM days d
    CROSS JOIN val_slash_agg va
    GROUP BY d.day
)
SELECT
    dv.day,
    dvt.still_registered_vaults,
    dvt.once_registered_vaults,
    dop.still_registered_operators,
    dop.once_registered_operators,
    dv.total_registered_validators,
    dv.once_registered_validators,
    dv.total_amount_staked
FROM daily_validators dv
JOIN daily_vaults dvt ON dv.day = dvt.day
JOIN daily_operators dop ON dv.day = dop.day
ORDER BY dv.day;
