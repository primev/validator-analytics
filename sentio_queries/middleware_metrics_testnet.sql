SELECT
  -- Vaults:
  -- (1) Still registered vaults: VaultRegistered with no dereg event.
  (
    SELECT COUNT(DISTINCT vault)
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'VaultRegistered'
      AND vault NOT IN (
        SELECT vault
        FROM mev_commit_middleware
        WHERE chain = '17000'
          AND eventType IN ('VaultDeregistrationRequested', 'VaultDeregistered')
      )
  ) AS still_registered_vaults,

  -- (2) Once registered vaults: VaultRegistered that later had a dereg event.
  (
    SELECT COUNT(DISTINCT vault)
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'VaultRegistered'
      AND vault IN (
        SELECT vault
        FROM mev_commit_middleware
        WHERE chain = '17000'
          AND eventType IN ('VaultDeregistrationRequested', 'VaultDeregistered')
      )
  ) AS once_registered_vaults,

  -- Operators:
  -- (3) Still registered operators: OperatorRegistered with no dereg event.
  (
    SELECT COUNT(DISTINCT operator)
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'OperatorRegistered'
      AND operator NOT IN (
        SELECT operator
        FROM mev_commit_middleware
        WHERE chain = '17000'
          AND eventType IN ('OperatorDeregistrationRequested', 'OperatorDeregistered')
      )
  ) AS still_registered_operators,

  -- (4) Once registered operators: OperatorRegistered that later had a dereg event.
  (
    SELECT COUNT(DISTINCT operator)
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'OperatorRegistered'
      AND operator IN (
        SELECT operator
        FROM mev_commit_middleware
        WHERE chain = '17000'
          AND eventType IN ('OperatorDeregistrationRequested', 'OperatorDeregistered')
      )
  ) AS once_registered_operators,

  -- Validators:
  -- (5) Total registered validators: ValRecordAdded events with no dereg event.
  (
    SELECT COUNT(DISTINCT blsPubkey)
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'ValRecordAdded'
      AND blsPubkey NOT IN (
        SELECT blsPubkey
        FROM mev_commit_middleware
        WHERE chain = '17000'
          AND eventType IN ('ValidatorDeregistrationRequested', 'ValRecordDeleted')
      )
  ) AS total_registered_validators,

  -- (6) Once registered validators: ValRecordAdded events that later had a dereg event.
  (
    SELECT COUNT(DISTINCT blsPubkey)
    FROM mev_commit_middleware
    WHERE chain = '17000'
      AND eventType = 'ValRecordAdded'
      AND blsPubkey IN (
        SELECT blsPubkey
        FROM mev_commit_middleware
        WHERE chain = '17000'
          AND eventType IN ('ValidatorDeregistrationRequested', 'ValRecordDeleted')
      )
  ) AS once_registered_validators,

  -- (7) Total amount staked:
  -- For each ValRecordAdded, join its vault to the corresponding VaultRegistered row (which provides slashAmount).
  (
    SELECT SUM(vr.slashAmount)
    FROM mev_commit_middleware val
    JOIN mev_commit_middleware vr 
      ON val.vault = vr.vault 
         AND vr.eventType = 'VaultRegistered'
         AND vr.chain = '17000'
    WHERE val.eventType = 'ValRecordAdded'
      AND val.chain = '17000'
  ) AS total_amount_staked

FROM mev_commit_middleware
LIMIT 1;
