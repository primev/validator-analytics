WITH all_slashes AS (
    SELECT
        toDate(timestamp) AS slash_day,
        eventType,
        amount
    FROM validator_slashes
    WHERE chain = '17000'
),
days AS (
    SELECT DISTINCT slash_day AS day
    FROM all_slashes
)
SELECT
    d.day,

    /* (1) Count of vanilla slash events (eventType='Slashed') up to d.day */
    SUM(
      CASE WHEN s.eventType = 'Slashed'
             AND s.slash_day <= d.day
           THEN 1 ELSE 0 END
    ) AS vanilla_slashes,

    /* (2) Count of AVS freeze events (eventType='ValidatorFrozen') up to d.day */
    SUM(
      CASE WHEN s.eventType = 'ValidatorFrozen'
             AND s.slash_day <= d.day
           THEN 1 ELSE 0 END
    ) AS avs_freezes,

    /* (3) Count of middleware slashes (eventType='ValidatorSlashed') up to d.day */
    SUM(
      CASE WHEN s.eventType = 'ValidatorSlashed'
             AND s.slash_day <= d.day
           THEN 1 ELSE 0 END
    ) AS middleware_slashes,

    /* (4) Count of vanilla + middleware slashes (exclude 'ValidatorFrozen') */
    SUM(
      CASE WHEN s.eventType IN ('Slashed','ValidatorSlashed')
             AND s.slash_day <= d.day
           THEN 1 ELSE 0 END
    ) AS total_slashes,

    /* (5) Sum of amounts for vanilla slashes */
    SUM(
      CASE WHEN s.eventType = 'Slashed'
             AND s.slash_day <= d.day
           THEN s.amount ELSE 0 END
    ) AS vanilla_total_amount,

    /* (6) Sum of amounts for middleware slashes */
    SUM(
      CASE WHEN s.eventType = 'ValidatorSlashed'
             AND s.slash_day <= d.day
           THEN s.amount ELSE 0 END
    ) AS middleware_total_amount,

    /* (7) Sum of amounts for both vanilla + middleware slashes */
    SUM(
      CASE WHEN s.eventType IN ('Slashed','ValidatorSlashed')
             AND s.slash_day <= d.day
           THEN s.amount ELSE 0 END
    ) AS overall_total_amount

FROM days d,
     all_slashes s
GROUP BY d.day
ORDER BY d.day;
