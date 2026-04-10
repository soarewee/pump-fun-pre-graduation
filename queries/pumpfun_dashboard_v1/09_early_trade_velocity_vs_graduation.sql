WITH launches AS (
    SELECT
        mint,
        min(evt_block_time) AS created_at
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
),
early_trade_counts AS (
    SELECT
        l.mint,
        count(t.mint) AS trades_first_5m,
        count(DISTINCT t.user) AS unique_traders_first_5m
    FROM launches l
    LEFT JOIN pumpdotfun_solana.pump_evt_tradeevent t
        ON t.mint = l.mint
       AND t.evt_block_date >= CURRENT_DATE - INTERVAL '21' DAY
       AND t.evt_block_time >= l.created_at
       AND t.evt_block_time < l.created_at + INTERVAL '5' MINUTE
    GROUP BY 1
),
token_labels AS (
    SELECT
        l.mint,
        CASE
            WHEN coalesce(e.trades_first_5m, 0) = 0 THEN '0 trades'
            WHEN e.trades_first_5m <= 5 THEN '1-5 trades'
            WHEN e.trades_first_5m <= 15 THEN '6-15 trades'
            WHEN e.trades_first_5m <= 30 THEN '16-30 trades'
            ELSE '31+ trades'
        END AS velocity_bucket,
        CASE
            WHEN coalesce(e.trades_first_5m, 0) = 0 THEN 1
            WHEN e.trades_first_5m <= 5 THEN 2
            WHEN e.trades_first_5m <= 15 THEN 3
            WHEN e.trades_first_5m <= 30 THEN 4
            ELSE 5
        END AS bucket_order,
        coalesce(e.unique_traders_first_5m, 0) AS unique_traders_first_5m,
        m.migrated_at IS NOT NULL
            AND m.migrated_at <= l.created_at + INTERVAL '7' DAY AS graduated_within_7d
    FROM launches l
    LEFT JOIN early_trade_counts e ON l.mint = e.mint
    LEFT JOIN migrations m ON l.mint = m.mint
)
SELECT
    bucket_order,
    velocity_bucket,
    count(*) AS tokens,
    avg(unique_traders_first_5m) AS avg_unique_traders_first_5m,
    count_if(graduated_within_7d) AS graduated_tokens,
    round(100.0 * count_if(graduated_within_7d) / count(*), 2) AS graduation_rate_7d_pct
FROM token_labels
GROUP BY 1, 2
ORDER BY 1;
