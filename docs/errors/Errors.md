# Errors

Custom error codes defined in `programs/onchain_escrow/src/errors.rs`.

## List
- `InvalidState` — Action not allowed in current state
- `Unauthorized` — Caller not permitted
- `ExpiredTicket` — ResolveTicket expired
- `SignatureInvalid` — Invalid arbiter signature
- `InsufficientFunds` — Token balance too low
- `CIDInvalid` — Malformed or missing CID
- `VaultMismatch` — Vault account mismatch

### Updates
- v1.0.0 — Initial creation

