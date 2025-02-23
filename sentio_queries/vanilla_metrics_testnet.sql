SELECT
    -- (1) Validators with Staked/StakeAdded but NO Unstaked/Withdrawn
    (SELECT COUNT(DISTINCT valBLSPubKey)
     FROM vanilla_registry_staking
     WHERE chain = '17000'
       AND eventType IN ('Staked', 'StakeAdded')
       AND valBLSPubKey NOT IN (
         SELECT valBLSPubKey
         FROM vanilla_registry_staking
         WHERE chain = '17000'
           AND eventType IN ('Unstaked', 'StakeWithdrawn')
       )
    ) AS total_registered_validators,

    -- (2) Sum of staked amounts for those still-registered validators
    (SELECT SUM(amount)
     FROM vanilla_registry_staking
     WHERE chain = '17000'
       AND eventType IN ('Staked', 'StakeAdded')
       AND valBLSPubKey NOT IN (
         SELECT valBLSPubKey
         FROM vanilla_registry_staking
         WHERE chain = '17000'
           AND eventType IN ('Unstaked', 'StakeWithdrawn')
       )
    ) AS total_staked_amount,

    -- (3) Distinct from_addresses for still-registered validators
    (SELECT COUNT(DISTINCT from_address)
     FROM vanilla_registry_staking
     WHERE chain = '17000'
       AND eventType IN ('Staked', 'StakeAdded')
       AND valBLSPubKey NOT IN (
         SELECT valBLSPubKey
         FROM vanilla_registry_staking
         WHERE chain = '17000'
           AND eventType IN ('Unstaked', 'StakeWithdrawn')
       )
    ) AS unique_stakers,

    -- (4) Validators that staked AND had an Unstaked/Withdrawn
    (SELECT COUNT(DISTINCT valBLSPubKey)
     FROM vanilla_registry_staking
     WHERE chain = '17000'
       AND eventType IN ('Staked', 'StakeAdded')
       AND valBLSPubKey IN (
         SELECT valBLSPubKey
         FROM vanilla_registry_staking
         WHERE chain = '17000'
           AND eventType IN ('Unstaked', 'StakeWithdrawn')
       )
    ) AS staked_and_unstaked_validator_count

FROM vanilla_registry_staking
LIMIT 1;
