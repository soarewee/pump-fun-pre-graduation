WITH create_mints AS (
    SELECT
        mint,
        min(evt_block_time) AS created_at
    FROM pumpdotfun_solana.pump_evt_createevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '7' DAY
    GROUP BY 1
),
trade_mints AS (
    SELECT
        mint,
        count(*) AS trade_rows,
        count(DISTINCT user) AS unique_traders,
        min(evt_block_time) AS first_trade_at,
        max(evt_block_time) AS last_trade_at
    FROM pumpdotfun_solana.pump_evt_tradeevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '7' DAY
    GROUP BY 1
),
complete_mints AS (
    SELECT DISTINCT mint
    FROM pumpdotfun_solana.pump_evt_completeevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '7' DAY
),
migrate_mints AS (
    SELECT DISTINCT mint
    FROM pumpdotfun_solana.pump_evt_completepumpammmigrationevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '7' DAY
)
SELECT
    count(*) AS launches_7d,
    count_if(t.mint IS NOT NULL) AS launches_with_trade_rows,
    count_if(t.trade_rows >= 10) AS launches_with_10plus_trades,
    count_if(c.mint IS NOT NULL) AS launches_with_complete_event,
    count_if(m.mint IS NOT NULL) AS launches_with_migration_event,
    approx_percentile(date_diff('second', created_at, t.first_trade_at), 0.5) AS median_secs_create_to_first_trade,
    approx_percentile(t.trade_rows, 0.5) AS median_trade_rows_per_token,
    approx_percentile(t.unique_traders, 0.5) AS median_unique_traders_per_token
FROM create_mints x
LEFT JOIN trade_mints t ON x.mint = t.mint
LEFT JOIN complete_mints c ON x.mint = c.mint
LEFT JOIN migrate_mints m ON x.mint = m.mint;
