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
ranked_trades AS (
    SELECT
        t.mint,
        t.user,
        cast(t.sol_amount AS double) AS sol_amount,
        row_number() OVER (
            PARTITION BY t.mint
            ORDER BY
                t.evt_block_time,
                t.evt_tx_id,
                t.evt_outer_instruction_index,
                t.evt_inner_instruction_index
        ) AS trade_number
    FROM pumpdotfun_solana.pump_evt_tradeevent t
    JOIN launches l
        ON t.mint = l.mint
    WHERE t.evt_block_date >= CURRENT_DATE - INTERVAL '21' DAY
      AND t.evt_block_time >= l.created_at
      AND t.evt_block_time < l.created_at + INTERVAL '10' MINUTE
),
early_trades AS (
    SELECT *
    FROM ranked_trades
    WHERE trade_number <= 20
),
wallet_sol AS (
    SELECT
        mint,
        user,
        sum(sol_amount) AS trader_sol
    FROM early_trades
    GROUP BY 1, 2
),
wallet_rank AS (
    SELECT
        mint,
        user,
        trader_sol,
        row_number() OVER (PARTITION BY mint ORDER BY trader_sol DESC, user) AS wallet_rank,
        sum(trader_sol) OVER (PARTITION BY mint) AS total_sol
    FROM wallet_sol
),
concentration AS (
    SELECT
        mint,
        sum(CASE WHEN wallet_rank <= 5 THEN trader_sol ELSE 0 END) AS top5_sol,
        max(total_sol) AS total_sol
    FROM wallet_rank
    GROUP BY 1
),
token_labels AS (
    SELECT
        l.mint,
        CASE
            WHEN c.total_sol IS NULL OR c.total_sol = 0 THEN 'no early trades'
            WHEN c.top5_sol / c.total_sol >= 0.90 THEN '90-100%'
            WHEN c.top5_sol / c.total_sol >= 0.75 THEN '75-90%'
            WHEN c.top5_sol / c.total_sol >= 0.50 THEN '50-75%'
            ELSE '<50%'
        END AS concentration_bucket,
        CASE
            WHEN c.total_sol IS NULL OR c.total_sol = 0 THEN 5
            WHEN c.top5_sol / c.total_sol >= 0.90 THEN 4
            WHEN c.top5_sol / c.total_sol >= 0.75 THEN 3
            WHEN c.top5_sol / c.total_sol >= 0.50 THEN 2
            ELSE 1
        END AS bucket_order,
        m.migrated_at IS NOT NULL
            AND m.migrated_at <= l.created_at + INTERVAL '7' DAY AS graduated_within_7d
    FROM launches l
    LEFT JOIN concentration c ON l.mint = c.mint
    LEFT JOIN migrations m ON l.mint = m.mint
)
SELECT
    bucket_order,
    concentration_bucket,
    count(*) AS tokens,
    count_if(graduated_within_7d) AS graduated_tokens,
    round(100.0 * count_if(graduated_within_7d) / count(*), 2) AS graduation_rate_7d_pct
FROM token_labels
GROUP BY 1, 2
ORDER BY 1;
