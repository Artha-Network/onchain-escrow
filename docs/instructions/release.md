# release

Releases funds to the seller when buyer approves completion.

- Type: Instruction
- Location: `programs/onchain_escrow/src/instructions/release.rs`

## Accounts
- `buyer: Signer`
- `escrow_state: Account<EscrowState>` (has_one=buyer)

## Emits
- `DealReleased`

## Consumed By
- `actions-server` release route
  - File: `actions-server/src/routes/release/index.ts`

### Updates
- v1.0.0 — Initial creation

