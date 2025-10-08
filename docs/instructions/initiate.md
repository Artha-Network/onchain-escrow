# initiate

Creates a new escrow state account for a deal.

- Type: Instruction
- Location: `programs/onchain_escrow/src/instructions/initiate.rs`
- Exposed in: `programs/onchain_escrow/src/lib.rs::initiate`

## Inputs
- `deal_id: u128`
- `fee_bps: u16`
- `deliver_deadline: i64`
- `dispute_deadline: i64`

## Accounts
- `seller: Signer` — pays rent; owner of deal setup
- `buyer: UncheckedAccount` — counterparty
- `escrow_state: EscrowState (init, seeds=["escrow", deal_id])`
- `system_program`

## Emits
- `DealInitiated`

## Depends On
- PDA derivation: `EscrowState` (`state/escrow_state.rs`)
- Events: `events.rs`

## Consumed By
- `actions-server` to build initiation transactions
  - File: `actions-server/src/routes/initiate/index.ts`

### Updates
- v1.0.0 — Initial creation

