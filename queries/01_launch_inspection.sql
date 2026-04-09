SELECT
    evt_block_time,
    evt_tx_id,
    evt_tx_signer,
    name,
    symbol,
    mint,
    bonding_curve,
    creator,
    user,
    timestamp,
    virtual_sol_reserves,
    virtual_token_reserves,
    real_token_reserves,
    token_total_supply
FROM pumpdotfun_solana.pump_evt_createevent
WHERE evt_block_date >= CURRENT_DATE - INTERVAL '7' DAY
ORDER BY evt_block_time DESC
LIMIT 10;
