WITH launches AS (
    SELECT
        mint,
        min(evt_block_time) AS created_at
    FROM pumpdotfun_solana.pump_evt_createevent
    WHERE evt_block_date BETWEEN CURRENT_DATE - INTERVAL '21' DAY AND CURRENT_DATE - INTERVAL '2' DAY
    GROUP BY 1
),
migrations AS (
    SELECT
        mint,
        min(evt_block_time) AS migrated_at
    FROM pumpdotfun_solana.pump_evt_completepumpammmigrationevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '21' DAY
    GROUP BY 1
),
lagged AS (
    SELECT
        l.mint,
        date_diff('minute', l.created_at, m.migrated_at) AS minutes_to_graduation
    FROM launches l
    JOIN migrations m ON l.mint = m.mint
    WHERE m.migrated_at >= l.created_at
),
bucketed AS (
    SELECT
        CASE
            WHEN minutes_to_graduation < 1 THEN 1
            WHEN minutes_to_graduation < 5 THEN 2
            WHEN minutes_to_graduation < 15 THEN 3
            WHEN minutes_to_graduation < 30 THEN 4
            WHEN minutes_to_graduation < 60 THEN 5
            WHEN minutes_to_graduation < 180 THEN 6
            WHEN minutes_to_graduation < 720 THEN 7
            ELSE 8
        END AS bucket_order,
        CASE
            WHEN minutes_to_graduation < 1 THEN '<1 min'
            WHEN minutes_to_graduation < 5 THEN '1-5 min'
            WHEN minutes_to_graduation < 15 THEN '5-15 min'
            WHEN minutes_to_graduation < 30 THEN '15-30 min'
            WHEN minutes_to_graduation < 60 THEN '30-60 min'
            WHEN minutes_to_graduation < 180 THEN '1-3 hr'
            WHEN minutes_to_graduation < 720 THEN '3-12 hr'
            ELSE '12+ hr'
        END AS graduation_lag_bucket
    FROM lagged
)
SELECT
    bucket_order,
    graduation_lag_bucket,
    count(*) AS tokens
FROM bucketed
GROUP BY 1, 2
ORDER BY 1;
