SELECT
    -- (1) Still-registered operators
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

    -- (2) Operators that eventually requested or completed dereg
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

    -- (3) Total registered validators (never requested or completed dereg)
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

    -- (4) 32 ETH (in Wei) * number of currently registered validators
    (
      32000000000000000000
      *
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

    -- (5) Validators who were once registered but now requested or completed dereg
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
