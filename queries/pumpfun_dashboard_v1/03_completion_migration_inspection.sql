WITH complete_rows AS (
    SELECT
        'complete' AS row_type,
        evt_block_time AS block_time,
        evt_tx_id AS tx_id,
        mint,
        bonding_curve,
        user,
        CAST(NULL AS varchar) AS pool,
        CAST(NULL AS uint256) AS sol_amount
    FROM pumpdotfun_solana.pump_evt_completeevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '30' DAY
    ORDER BY evt_block_time DESC
    LIMIT 10
),
migrate_rows AS (
    SELECT
        'migrate' AS row_type,
        evt_block_time AS block_time,
        evt_tx_id AS tx_id,
        mint,
        bonding_curve,
        user,
        pool,
        sol_amount
    FROM pumpdotfun_solana.pump_evt_completepumpammmigrationevent
    WHERE evt_block_date >= CURRENT_DATE - INTERVAL '30' DAY
    ORDER BY evt_block_time DESC
    LIMIT 10
)
SELECT *
FROM (
    SELECT * FROM complete_rows
    UNION ALL
    SELECT * FROM migrate_rows
) x
ORDER BY block_time DESC
LIMIT 20;
