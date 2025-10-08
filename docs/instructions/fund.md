# fund

Buyer deposits funds into the escrow vault (Token-2022). This scaffold only updates status and emits an event.

- Type: Instruction
- Location: `programs/onchain_escrow/src/instructions/fund.rs`

## Inputs
- `amount: u64`

## Accounts
- `buyer: Signer`
- `escrow_state: Account<EscrowState>` (has_one=buyer)

## Emits
- `DealFunded`

## Consumed By
- `actions-server` funding route
  - File: `actions-server/src/routes/fund/index.ts`

### Updates
- v1.0.0 — Initial creation

