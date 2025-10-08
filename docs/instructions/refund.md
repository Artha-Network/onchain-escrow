# refund

Refunds the buyer (e.g., due to dispute outcome or timeout) and closes the deal.

- Type: Instruction
- Location: `programs/onchain_escrow/src/instructions/refund.rs`

## Accounts
- `seller: Signer` — initiates refund (or governed auth in future)
- `escrow_state: Account<EscrowState>`

## Emits
- `DealRefunded`

### Updates
- v1.0.0 — Initial creation

