SELECT
    -- (1) Still-registered operators: OperatorRegistered without a later dereg event.
    (
      SELECT COUNT(DISTINCT operator)
      FROM mev_commit_avs
      WHERE eventType = 'OperatorRegistered'
        AND chain = '17000'
        AND operator NOT IN (
          SELECT operator
          FROM mev_commit_avs
          WHERE eventType IN ('OperatorDeregistrationRequested', 'OperatorDeregistered')
            AND chain = '17000'
        )
    ) AS registered_operators,

    -- (2) Once-registered operators: those that registered and later deregistered.
    (
      SELECT COUNT(DISTINCT operator)
      FROM mev_commit_avs
      WHERE eventType = 'OperatorRegistered'
        AND chain = '17000'
        AND operator IN (
          SELECT operator
          FROM mev_commit_avs
          WHERE eventType IN ('OperatorDeregistrationRequested', 'OperatorDeregistered')
            AND chain = '17000'
        )
    ) AS once_registered_operators,

    -- (3) Total registered validators: ValidatorRegistered events with no subsequent dereg event.
    (
      SELECT COUNT(DISTINCT validatorPubKey)
      FROM mev_commit_avs
      WHERE eventType = 'ValidatorRegistered'
        AND chain = '17000'
        AND validatorPubKey NOT IN (
          SELECT validatorPubKey
          FROM mev_commit_avs
          WHERE eventType IN ('ValidatorDeregistrationRequested', 'ValidatorDeregistered')
            AND chain = '17000'
        )
    ) AS total_registered_validators,

    -- (4) Unique pod owners: distinct podOwner from ValidatorRegistered events (for validators that never deregistered)
    (
      SELECT COUNT(DISTINCT podOwner)
      FROM mev_commit_avs
      WHERE eventType = 'ValidatorRegistered'
        AND chain = '17000'
        AND podOwner IS NOT NULL
        AND podOwner <> ''
        AND validatorPubKey NOT IN (
          SELECT validatorPubKey
          FROM mev_commit_avs
          WHERE eventType IN ('ValidatorDeregistrationRequested', 'ValidatorDeregistered')
            AND chain = '17000'
        )
    ) AS unique_pod_owners,

    -- (5) Total restaked in wei: 32 ETH (in wei) multiplied by the number of still-registered validators.
    (
      32000000000000000000 *
      (
        SELECT COUNT(DISTINCT validatorPubKey)
        FROM mev_commit_avs
        WHERE eventType = 'ValidatorRegistered'
          AND chain = '17000'
          AND validatorPubKey NOT IN (
            SELECT validatorPubKey
            FROM mev_commit_avs
            WHERE eventType IN ('ValidatorDeregistrationRequested', 'ValidatorDeregistered')
              AND chain = '17000'
          )
      )
    ) AS total_restaked_in_wei,

    -- (6) Once-registered validators: those that registered and later deregistered.
    (
      SELECT COUNT(DISTINCT validatorPubKey)
      FROM mev_commit_avs
      WHERE eventType = 'ValidatorRegistered'
        AND chain = '17000'
        AND validatorPubKey IN (
          SELECT validatorPubKey
          FROM mev_commit_avs
          WHERE eventType IN ('ValidatorDeregistrationRequested', 'ValidatorDeregistered')
            AND chain = '17000'
        )
    ) AS once_registered_validators

FROM mev_commit_avs
LIMIT 1;
