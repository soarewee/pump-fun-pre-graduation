SELECT
    evt_block_time,
    evt_tx_id,
    evt_tx_signer,
    mint,
    user,
    creator,
    is_buy,
    sol_amount,
    token_amount,
    virtual_sol_reserves,
    virtual_token_reserves,
    real_sol_reserves,
    real_token_reserves,
    current_sol_volume,
    ix_name,
    evt_is_inner,
    evt_outer_instruction_index,
    evt_inner_instruction_index
FROM pumpdotfun_solana.pump_evt_tradeevent
WHERE evt_block_date >= CURRENT_DATE - INTERVAL '7' DAY
ORDER BY evt_block_time DESC
LIMIT 10;
