# pump.fun Pre-Graduation Research Notes

This repository is focused on researching **pump.fun tokens before graduation / AMM migration** on Solana using Dune.

## Dune Access In This Repo

This workspace now includes a small repo-local CLI at `./bin/dune`.

Setup:

1. Create a Dune API key from https://dune.com/settings/api
2. Copy `.env.example` to `.env`
3. Export the key in your shell:

```bash
export DUNE_API_KEY=your_api_key_here
```

Examples:

```bash
./bin/dune run --file queries/pumpfun_dashboard_v1/04_coverage_summary.sql
./bin/dune exec-sql --file queries/pumpfun_dashboard_v1/01_launch_inspection.sql
./bin/dune status <execution_id>
./bin/dune results <execution_id>
```

Inside Codex, the Dune MCP toolset is already active for this workspace. The local CLI is for direct terminal usage against the same Dune API.

## Summary

Dune appears to have enough usable decoded data to support a serious pre-graduation analysis for pump.fun.

The key conclusion from live schema inspection and sample queries is:

- token launches are explicit
- bonding-curve trades are explicit
- completion and migration are explicit
- graduation labeling is feasible
- early-stage feature engineering is feasible directly in Dune

## Validated Dune Tables

The main decoded schema is:

- `pumpdotfun_solana`

The most important tables found in that schema are:

- `pumpdotfun_solana.pump_evt_createevent`
- `pumpdotfun_solana.pump_evt_tradeevent`
- `pumpdotfun_solana.pump_evt_completeevent`
- `pumpdotfun_solana.pump_evt_completepumpammmigrationevent`
- `pumpdotfun_solana.pump_call_create`
- `pumpdotfun_solana.pump_call_buy`
- `pumpdotfun_solana.pump_call_sell`
- `pumpdotfun_solana.pump_call_migrate`

There is also a post-graduation AMM schema surface:

- `pumpdotfun_solana.pump_amm_evt_createpoolevent`
- `pumpdotfun_solana.pump_amm_evt_buyevent`
- `pumpdotfun_solana.pump_amm_evt_sellevent`

## Raw Solana Fallback

If decoded coverage looks suspicious for any edge case, the main fallback table is:

- `solana.instruction_calls`

Why this matters:

- it exists on Dune
- it can be used to validate instruction coverage
- it is the right low-level fallback for protocol tracing

Notable schema facts:

- partition columns include `block_time` and `executing_account`
- it includes inner and outer instruction indices
- it includes `account_arguments`, `tx_id`, `tx_signer`, and log messages

## Layer A: Token Launches

The best launch table currently looks like:

- `pumpdotfun_solana.pump_evt_createevent`

Validated fields:

- `mint`
- `creator`
- `user`
- `evt_block_time`
- `evt_tx_id`
- `name`
- `symbol`
- `bonding_curve`
- `timestamp`
- `virtual_sol_reserves`
- `virtual_token_reserves`
- `real_token_reserves`
- `token_total_supply`

Interpretation:

- one row per token launch appears feasible
- `mint` is the token identifier
- `creator` and `user` are both present
- the creation transaction id and timestamp are explicit
- bonding curve address is explicit

## Layer B: Bonding-Curve Trades

The best trade table currently looks like:

- `pumpdotfun_solana.pump_evt_tradeevent`

Validated fields:

- `mint`
- `user`
- `creator`
- `is_buy`
- `sol_amount`
- `token_amount`
- `evt_block_time`
- `evt_tx_id`
- `evt_tx_signer`
- `virtual_sol_reserves`
- `virtual_token_reserves`
- `real_sol_reserves`
- `real_token_reserves`
- `ix_name`

Interpretation:

- one row per trade is feasible
- buy and sell side are explicit
- reserve-state fields are available, which is useful for reconstructing trajectory
- `ix_name` distinguishes variants such as `buy`, `sell`, and `buy_exact_sol_in`

## Layer C: Outcome / Graduation Labels

The best outcome tables currently look like:

- `pumpdotfun_solana.pump_evt_completeevent`
- `pumpdotfun_solana.pump_evt_completepumpammmigrationevent`

Validated fields on completion / migration:

- `mint`
- `bonding_curve`
- `evt_block_time`
- `evt_tx_id`
- `user`
- `pool` on migration
- `sol_amount` on migration

Interpretation:

- `completeevent` is a strong candidate for "bonding curve completed"
- `completepumpammmigrationevent` is a strong candidate for "graduated / migrated to AMM"
- for practical labeling, migration is likely the cleanest graduation label

## What Was Verified Live

Recent sample rows were inspected on Dune on **2026-04-09**.

Observed directly:

- recent launch rows exist in `pump_evt_createevent`
- recent trade rows exist in `pump_evt_tradeevent`
- recent completion rows exist in `pump_evt_completeevent`
- recent migration rows exist in `pump_evt_completepumpammmigrationevent`
- completion and migration rows join cleanly on `mint`

Recent launches showed:

- real token names and symbols
- explicit mint and bonding curve addresses
- creator wallet populated

Recent trades showed:

- both buys and sells
- explicit users and creators
- explicit reserve state
- many rows marked as inner events, which suggests the decoded event stream is capturing inner execution paths

## Coverage Numbers

From a 7-day coverage summary query:

- launches: `192,814`
- launches with trade rows: `181,295`
- launches with at least 10 trades: `114,866`
- launches with complete event: `1,449`
- launches with migration event: `1,449`
- median seconds from create to first trade: `0`
- median trade rows per token: `15`
- median unique traders per token: `5`

From a completion-to-migration lag query:

- matched tokens: `1,982`
- median seconds from complete to migrate: `1`
- min seconds from complete to migrate: `0`
- max seconds from complete to migrate: `6`

## Feasibility Assessment

Current judgment:

- **Yes, pump.fun pre-graduation analysis looks feasible on Dune**

Reasoning:

- launch rows are explicit
- trade rows are explicit and already side-labeled
- pre-graduation reserve state is available
- completion and migration are explicit
- the data volume is high enough for feature engineering and cohort analysis

## Caveats

Important caveats to keep in mind:

- `pump_evt_tradeevent` often appears as an inner event, so edge-case validation against raw Solana tables is still worth doing
- decoded tables may still miss some weird paths or older-version behavior
- `current_sol_volume` looked unreliable in sampled rows and should not be trusted without validation
- if a claim depends on perfect instruction completeness, validate with `solana.instruction_calls`
- pre-graduation analysis should be explicitly separated from post-migration AMM trading

## Recommended Data Model

### Launch table

One row per token launch:

- `mint`
- `creator`
- `created_at`
- `creation_tx`
- `name`
- `symbol`
- `bonding_curve`

### Trade table

One row per pre-graduation trade:

- `mint`
- `trade_time`
- `tx_id`
- `trader`
- `is_buy`
- `sol_amount`
- `token_amount`
- `trade_index_within_token`

### Feature table

One row per token with early-window features:

- trades in first 1m / 5m / 30m
- unique traders
- buy/sell ratio
- net SOL flow
- top-1 / top-5 wallet concentration
- creator participation
- median trade size
- time to first 10 trades
- time to first sell
- graduation label
- time to graduation

## First Five Queries To Run

These queries were created during exploration:

1. Launch inspection
   - Query ID: `6970652`
   - URL: `https://dune.com/queries/6970652`

2. Trade inspection
   - Query ID: `6970653`
   - URL: `https://dune.com/queries/6970653`

3. Completion and migration inspection
   - Query ID: `6970654`
   - URL: `https://dune.com/queries/6970654`

4. 7-day coverage summary
   - Query ID: `6970662`
   - URL: `https://dune.com/queries/6970662`

5. Completion-to-migration lag summary
   - Query ID: `6970663`
   - URL: `https://dune.com/queries/6970663`

## Suggested Next Query

The next practical query should be a first-pass early-feature table for the first 30 minutes after launch.

Suggested outputs:

- trades in first 30m
- unique traders in first 30m
- buys and sells in first 30m
- net SOL flow in first 30m
- average and median trade size
- time to first trade
- time to first sell

## Working Conclusion

The most important result from the initial investigation is:

> Dune already exposes a credible decoded event surface for pump.fun pre-graduation behavior, and it is likely sufficient to build a defensible first version of the research and dashboard without starting from raw Solana parsing.

The main thing still worth validating is not basic availability, but **coverage quality at the edges**.
