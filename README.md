# Onchain Escrow (Solana • Anchor)

Smart-contract (program) for decentralized, AI-assisted escrow on **Solana**. Holds funds (USDC/SPL), enforces a strict state machine, and verifies signed **ResolveTickets** from the Arbiter.

## Features
- Deterministic **PDA**-backed `EscrowState`
- USDC custody via **SPL Token-2022** (optional transfer hook guard)
- Instructions: `initiate`, `fund`, `submit_evidence`, `open_dispute`, `resolve`, `release`, `refund`
- **Pyth** USD price snapshot on funding
- Events for off-chain indexers (Helius/QuickNode)
- Defensive checks: signer roles, nonce/expiry, replay protection

## Repo Layout
programs/escrow/
src/
accounts/ # PDAs & account validation
instructions/ # anchor handlers per ix
token_hooks/ # (optional) transfer hook guard
utils/ # pyth, seeds, math
state.rs # enums, constants
events.rs
errors.rs
lib.rs
idl/escrow.json # exported IDL
tests/ # anchor tests (ts/rs)

## Build & Test (Local)
```bash
# 1) Start local validator (in dev-infra or on your own) then:
anchor build
anchor test
Environment
Var	Description
USDC_MINT	SPL USDC mint (dev/main)
PYTH_SOLUSD	Pyth price feed pubkey
PROGRAM_UPGRADE_AUTHORITY	Upgrade authority (multisig recommended)
Instruction Summary
initiate(args) → Create PDA, set terms (price, deadlines, fee_bps), emit event.
fund(amount) → Transfer USDC → vault ATA; record Pyth snapshot.
submit_evidence(cid_hash) → Append CID hash; enforce limits.
open_dispute() → Transition FUNDED → DISPUTED.
resolve(ticket, sig) → Verify arbiter sig/nonce/expiry; set RESOLVED.
release()/refund() → Transfer out of vault per resolution.
Security Notes
All token movement via program-owned vault ATA.
Optional Token-2022 Transfer Hook to block unauthorized releases.
Nonces for ResolveTicket replay protection.
Ship with external audit before mainnet.
License
MIT

---
