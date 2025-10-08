# open_dispute

Transitions a funded deal into the Disputed state.

- Type: Instruction
- Location: `programs/onchain_escrow/src/instructions/open_dispute.rs`

## Accounts
- `caller: Signer` — must be buyer or seller
- `escrow_state: Account<EscrowState>`

## Emits
- `DealDisputed`

### Updates
- v1.0.0 — Initial creation

