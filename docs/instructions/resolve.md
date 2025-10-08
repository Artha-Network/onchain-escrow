# resolve

Applies an AI Arbiter-signed decision to a disputed deal.

- Type: Instruction
- Location: `programs/onchain_escrow/src/instructions/resolve.rs`

## Inputs
- `action: ResolutionAction` — `Release | Refund | Split(bps)`
- `nonce: u64` — replay protection
- `expires_at: i64` — epoch seconds
- `sig: [u8; 64]` — ed25519 signature over canonical ticket

## Accounts
- `arbiter: UncheckedAccount` — allowlisted arbiter, signature verified
- `escrow_state: Account<EscrowState>`

## Emits
- `DealResolved`

## Depends On
- `arbiter-service` (produces signed ResolveTicket)
- `tickets-lib` (shared schema/signing vectors)

## Provides To
- `actions-server` for building release/refund txs post-resolution

### Updates
- v1.0.0 — Initial creation

