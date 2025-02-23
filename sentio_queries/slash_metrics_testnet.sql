SELECT
  -- (1) Vanilla slashes: count events where eventType = 'Slashed'
  (SELECT COUNT(*)
   FROM validator_slashes
   WHERE chain = '17000'
     AND eventType = 'Slashed'
  ) AS vanilla_slashes,

  -- (2) AVS freezes: count events where eventType = 'ValidatorFrozen'
  (SELECT COUNT(*)
   FROM validator_slashes
   WHERE chain = '17000'
     AND eventType = 'ValidatorFrozen'
  ) AS avs_freezes,

  -- (3) Middleware slashes: count events where eventType = 'ValidatorSlashed'
  (SELECT COUNT(*)
   FROM validator_slashes
   WHERE chain = '17000'
     AND eventType = 'ValidatorSlashed'
  ) AS middleware_slashes,

  -- (4) Total slashes: count of vanilla + middleware slashes (exclude AVS freezes)
  (SELECT COUNT(*)
   FROM validator_slashes
   WHERE chain = '17000'
     AND eventType IN ('Slashed', 'ValidatorSlashed')
  ) AS total_slashes,

  -- (5) Vanilla total amount: sum of amounts for eventType = 'Slashed'
  (SELECT SUM(amount)
   FROM validator_slashes
   WHERE chain = '17000'
     AND eventType = 'Slashed'
  ) AS vanilla_total_amount,

  -- (6) Middleware total amount: sum of amounts for eventType = 'ValidatorSlashed'
  (SELECT SUM(amount)
   FROM validator_slashes
   WHERE chain = '17000'
     AND eventType = 'ValidatorSlashed'
  ) AS middleware_total_amount,

  -- (7) Overall total amount: sum of amounts for vanilla and middleware slashes
  (SELECT SUM(amount)
   FROM validator_slashes
   WHERE chain = '17000'
     AND eventType IN ('Slashed', 'ValidatorSlashed')
  ) AS overall_total_amount

FROM validator_slashes
LIMIT 1;
