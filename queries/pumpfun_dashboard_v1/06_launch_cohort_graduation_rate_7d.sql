WITH launches AS (
    SELECT
        mint,
        min(evt_block_time) AS created_at,
        date_trunc('day', min(evt_block_time)) AS launch_day
    FROM pumpdotfun_solana.pump_evt_createevent
    WHERE evt_block_date BETWEEN CURRENT_DATE - INTERVAL '21' DAY AND CURRENT_DATE - INTERVAL '8' DAY
    GROUP BY 1
),
migrations AS (
    SELECT
        mint,
        min(evt_block_time) AS migrated_at
    FROM pumpdotfun_solana.pump_evt_completepumpammmigrationevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '21' DAY
    GROUP BY 1
)
SELECT
    launch_day,
    count(*) AS launches,
    count_if(m.migrated_at IS NOT NULL AND m.migrated_at <= l.created_at + INTERVAL '7' DAY) AS graduated_within_7d,
    round(
        100.0 * count_if(m.migrated_at IS NOT NULL AND m.migrated_at <= l.created_at + INTERVAL '7' DAY)
        / count(*),
        2
    ) AS graduation_rate_7d_pct
FROM launches l
LEFT JOIN migrations m ON l.mint = m.mint
GROUP BY 1
ORDER BY 1;
