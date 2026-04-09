WITH complete_rows AS (
    SELECT
        mint,
        min(evt_block_time) AS complete_time
    FROM pumpdotfun_solana.pump_evt_completeevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '7' DAY
    GROUP BY 1
),
migrate_rows AS (
    SELECT
        mint,
        min(evt_block_time) AS migrate_time
    FROM pumpdotfun_solana.pump_evt_completepumpammmigrationevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '7' DAY
    GROUP BY 1
)
SELECT
    approx_percentile(date_diff('second', c.complete_time, m.migrate_time), 0.5) AS median_seconds_complete_to_migrate,
    min(date_diff('second', c.complete_time, m.migrate_time)) AS min_seconds_complete_to_migrate,
    max(date_diff('second', c.complete_time, m.migrate_time)) AS max_seconds_complete_to_migrate,
    count(*) AS matched_tokens
FROM complete_rows c
JOIN migrate_rows m ON c.mint = m.mint;
