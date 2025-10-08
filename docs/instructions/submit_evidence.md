# submit_evidence

Appends an evidence CID (Arweave/IPFS) to the disputed deal.

- Type: Instruction
- Location: `programs/onchain_escrow/src/instructions/submit_evidence.rs`

## Inputs
- `cid: String`

## Accounts
- `caller: Signer`
- `escrow_state: Account<EscrowState>`

## Emits
- `EvidenceSubmitted`

## Depends On
- `storage-lib` for CID validation (off-chain)

### Updates
- v1.0.0 — Initial creation

