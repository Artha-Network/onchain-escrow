# Dependencies (Onchain Escrow)

This document lists on-chain program dependencies, external crates, and cross-repo interactions. It is intended for auditors and integrators.

## Crates
- `anchor-lang` (>= 0.30.1)
  - Purpose: Anchor macros (`#[program]`, `#[account]`, events, errors) and runtime
  - Usage: program definition, account serialization, events, error codes
- `anchor-spl` (>= 0.30.1)
  - Purpose: SPL token interfaces (Token/Token-2022) and CPI helpers
  - Usage: token transfers to/from program-owned vaults (future work)
- `solana-program` (>= 1.18)
  - Purpose: Solana SDK for low-level types (`Pubkey`, system program), CPI

## Internal Modules
- `state/escrow_state.rs` — primary PDA account; escrow lifecycle data
- `state/enums.rs` — `DealStatus` enum for state machine
- `state/price_snapshot.rs` — Pyth USD snapshot storage
- `instructions/*` — one file per instruction (initiate, fund, open_dispute, submit_evidence, resolve, release, refund)
- `events.rs` — on-chain events consumed by indexers/jobs-service
- `errors.rs` — custom error codes enforcing invariants
- `utils.rs` — shared validation/utilities (kept minimal)

## Cross-Repo Interactions
- actions-server
  - Role: builds ready-to-sign transactions hitting `initiate`, `fund`, `release`, `dispute`, `resolve`
  - File: `actions-server/src/services/escrow-service.ts`
  - Contract: instruction accounts/args must match program IDL
- arbiter-service
  - Role: issues signed ResolveTickets
  - Contract: `resolve` verifies ed25519 signatures, nonce/expiry
- jobs-service
  - Role: monitors program logs and events
  - Contract: consumes `DealInitiated`, `DealFunded`, `DealResolved`, etc.
- storage-lib
  - Role: validates evidence CIDs and stores content (Arweave/IPFS)
  - Contract: `submit_evidence` expects valid CID formats
- tickets-lib
  - Role: shared schema for ResolveTicket; signature verify helpers (future)

## PDA Seeds (Deterministic)
- `EscrowState`: seeds = [`b"escrow"`, `deal_id.to_be_bytes()`]
- `Vault (Token-2022 ATA)`: seeds = [`b"vault"`, `deal_id.to_be_bytes()`]

## Notes
- All on-chain token movements are performed via program-owned vault accounts. No direct fund custody by EOAs.
- This repo contains scaffolding; token CPI and Pyth verification to be implemented per audit guidance.

### Updates
- v1.0.0 — Initial creation

