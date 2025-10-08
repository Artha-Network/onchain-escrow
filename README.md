# 🧩 Artha Network – Onchain Escrow Program

> **Module:** `onchain-escrow`  
> **Language:** Rust (Anchor Framework)  
> **Network:** Solana  
> **Author:** Tylenol Plus Team – Artha Network  
> **Version:** v1.0  
> **Date:** October 2025

---

## 1. Overview

The **onchain-escrow program** is the **custodial backbone** of the Artha Network decentralized escrow system.  
It governs **fund custody, deal states, evidence references, and dispute resolutions** directly on the Solana blockchain using **Rust + Anchor**.

All escrow logic — including creation, funding, dispute resolution, and release/refund — executes entirely on-chain.  
Funds are locked deterministically in **Program-Derived Accounts (PDAs)**, ensuring no party (including Artha) can unilaterally access them.

### Key Responsibilities

- Secure custody of funds (USDC via SPL Token-2022)
- Immutable state machine for escrow lifecycle
- Evidence CID anchoring (Arweave/IPFS)
- AI or human arbitration through signed **ResolveTickets**
- Gas-sponsored transactions for new users

---

## 2. Architectural Role

The `onchain-escrow` program serves as the **authoritative contract** for deal management.  
It interacts with Artha’s off-chain services:

[Web App / Blink Link]
↓
[Actions Server] → Builds Solana TX
↓
[onchain-escrow Program] → Executes state transitions
↓
[Jobs / Arbiter / Notifications]

- **Actions Server:** Builds ready-to-sign Solana transactions
- **Arbiter Service:** Issues signed `ResolveTicket` decisions
- **Jobs Service:** Monitors program logs, triggers timeouts & reminders
- **Storage-lib:** Validates evidence CIDs (Arweave/IPFS)

---

## 3. Core Accounts and Data Model

### 3.1 EscrowState Account

```rust
#[account]
pub struct EscrowState {
    pub deal_id: u128,
    pub seller: Pubkey,
    pub buyer: Pubkey,
    pub arbiter_pubkey: Pubkey,
    pub price_usd_cents: u64,
    pub deposit_token_mint: Pubkey, // e.g., USDC
    pub vault_ata: Pubkey,
    pub created_at: i64,
    pub funded_at: Option<i64>,
    pub deliver_deadline: i64,
    pub dispute_deadline: i64,
    pub usd_price_snapshot: PriceSnapshot,
    pub status: DealStatus,
    pub evidence_cids: Vec<String>,
    pub rationale_cid: Option<String>,
    pub fee_bps: u16,
    pub payout_splits: Option<Vec<(Pubkey, u16)>>, // % split
    pub nonce: u64,
}
3.2 Supporting Structs
rust
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq)]
pub enum DealStatus {
    Init,
    Funded,
    Delivered,
    Disputed,
    Resolved,
    Released,
    Refunded,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct PriceSnapshot {
    pub feed_id: [u8; 32],
    pub price: i64,
    pub conf: u64,
    pub slot: u64,
}
3.3 Vault ATA
Program-owned Token-2022 vault (seed: [b"vault", deal_id])

Authority: PDA derived from program ID

Locked until resolved via resolve(), release(), or refund()

4. Instruction Set
Instruction	Description	Preconditions	Postconditions
initiate()	Creates a new escrow state	Called by seller; unique deal_id	Status = Init
fund()	Buyer deposits USDC	Buyer must hold enough balance	Status → Funded
open_dispute()	Moves deal into dispute state	Must be buyer/seller; Funded state	Status = Disputed
submit_evidence()	Links Arweave/IPFS CIDs	Deal = Disputed	CID added; event emitted
resolve(ticket)	Applies arbiter’s decision	Valid signature & expiry	Funds distributed; Resolved
release()	Buyer approves completion	Funded or Delivered state	Funds → Seller; Released
refund()	Refunds buyer	Funded or Disputed	Funds → Buyer; Refunded

5. State Machine

INIT → FUNDED → (DELIVERED) → [DISPUTED] → RESOLVED → RELEASED/REFUNDED
                   \
                    → TIMEOUT → REFUNDED
Invalid transitions revert with InvalidState.

Enforced entirely within Anchor account constraints.

6. Security Invariants
Category	Rule	Enforcement
Custody	Funds move only via authorized instructions	Token-2022 Transfer Hook
Signature	Only allowlisted arbiters can sign decisions	Allowlist in config PDA
Replay Protection	Tickets require unique nonce & expiry	Prevent duplicates
Ownership	Vaults derived from deterministic PDAs	Anchor seeds check
Re-init Protection	No duplicate initialization	Anchor init constraints
Fee Safety	Transfers ≤ recorded price	Prevent over-withdrawal
Upgrade Safety	Multisig + timelock authority	Prevent malicious upgrades

7. Events
Event	Fields	Description
DealCreated	deal_id, seller, buyer, price	New escrow created
DealFunded	deal_id, amount	USDC deposited
EvidenceSubmitted	deal_id, cid	Evidence added
DealDisputed	deal_id	Dispute opened
DealResolved	deal_id, action, arbiter	Arbiter decision enforced
DealReleased	deal_id	Buyer released funds
DealRefunded	deal_id	Refund executed

8. Anchor Constraints Example
rust
#[account(
  mut,
  seeds = [b"escrow", deal_id.to_be_bytes().as_ref()],
  bump,
  has_one = seller,
  has_one = buyer,
  constraint = escrow_state.status == DealStatus::Funded @ ErrorCode::InvalidState
)]
pub escrow_state: Account<'info, EscrowState>;
Transfer guard:

rust
#[account(
  mut,
  constraint = escrow_state.status == DealStatus::Resolved
)]
pub vault_ata: Account<'info, TokenAccount>;
9. Error Codes
Code	Description
InvalidState	Action not allowed in current state
Unauthorized	Caller not permitted
ExpiredTicket	ResolveTicket expired
SignatureInvalid	Invalid arbiter signature
InsufficientFunds	Token balance too low
CIDInvalid	Malformed or missing CID
VaultMismatch	Vault account mismatch

10. Testing Plan
Unit Tests
test_initiate_fund_release()

test_dispute_and_resolve_refund()

test_invalid_state_transitions()

test_signature_verification()

test_fee_split_logic()

Integration Tests
Local validator with mock USDC mint

Mock Arbiter Service issuing signed ResolveTickets

Verify correct fund flow and event emissions

Fuzz & Stress Tests
Concurrent fund/release operations

Randomized disputes at scale (10k deals)

11. Deployment
Env	Network	Program ID	Vault Owner
Dev	Localnet	ArthaEscrow1111111...	PDA
Staging	Testnet	EscrowStage9999999...	PDA
Prod	Mainnet-Beta	EscrowMain111111...	PDA

Upgrade Governance
Controlled by 3/5 multisig (Lead Dev, PM, Security Lead)

48h timelock before upgrade finalization

All upgrades verified via Solana Explorer & cargo audit

12. Integration Points
Service	Role	Interaction
Actions Server	Builds tx payloads	Calls initiate(), fund(), resolve()
Arbiter Service	Issues signed tickets	Verified on-chain
Jobs Service	Monitors logs	Triggers timers, reminders
Storage-lib	CID validation	Validates Arweave/IPFS hashes
Tickets-lib	Schema parity	CBOR + Zod schemas shared

13. Metrics & Observability
Tracked Metrics

time_to_fund and time_to_resolve

Dispute frequency

Arbiter confidence histogram

Vault balance anomalies

Reliability Targets

99.9% availability

<2s transaction latency (95th percentile)

0 unresolved S1 vulnerabilities at deploy

14. Future Roadmap
Version	Feature	Description
v1.1	Multi-token deposits	Auto-swap to USDC
v1.2	Partial settlements	Milestone-based release
v1.3	DAO arbitration	On-chain juror voting
v2.0	Cross-chain escrow	LayerZero/Wormhole integration

15. Summary
The onchain-escrow program is the core trust engine of Artha Network.
It enforces transparent, tamper-proof escrow logic on Solana, enabling AI-driven dispute resolution while keeping custody decentralized.

Security, auditability, and simplicity drive every design choice.
Once deployed, this program becomes the source of truth for all escrowed funds and deal states across the Artha ecosystem.

16. Developer Setup
Prerequisites
Rust + Cargo nightly

Anchor CLI (cargo install --git https://github.com/coral-xyz/anchor anchor-cli)

Solana CLI (solana-install init)

Node.js ≥ 18 (for IDL + build scripts)

Build & Test

# Install dependencies
anchor build

# Run local validator + tests
anchor test

# Deploy to devnet
solana config set --url https://api.devnet.solana.com
anchor deploy
Folder Structure

onchain-escrow/
├── programs/
│   └── onchain_escrow/
│       ├── src/
│       │   ├── lib.rs
│       │   ├── instructions/
│       │   ├── state/
│       │   └── errors.rs
│       └── Cargo.toml
├── Anchor.toml
├── tests/
│   └── escrow_flow.ts
└── README.md
17. License
This project is part of the Artha Network ecosystem.
© 2025 Tylenol Plus Team – University of North Texas
Licensed under the MIT License.
```
