# ⚙️ Artha Network – Onchain Escrow Coding Conventions

**Repository:** `onchain-escrow`  
**Language:** Rust  
**Framework:** Anchor (Solana)  
**Maintainers:** Blockchain Engineering Team – Artha Network  
**Version:** 1.0  
**Date:** October 2025

---

## 1. 🎯 Purpose

Establish clear conventions for **secure, auditable, and modular Rust development** inside the Artha Network’s onchain escrow program.  
This ensures:

- Consistent coding style across all contributors
- Simplified auditing and testing
- Seamless integration with off-chain systems (Actions Server, Arbiter Service, Jobs Service)

---

## 2. 🧩 Project Structure

The repository follows a **standard Anchor layout**:

programs/
└── onchain_escrow/
├── src/
│ ├── instructions/
│ │ ├── initiate.rs
│ │ ├── fund.rs
│ │ ├── open_dispute.rs
│ │ ├── submit_evidence.rs
│ │ ├── resolve.rs
│ │ ├── release.rs
│ │ └── refund.rs
│ ├── state/
│ │ ├── escrow_state.rs
│ │ ├── price_snapshot.rs
│ │ └── enums.rs
│ ├── errors.rs
│ ├── events.rs
│ ├── utils.rs
│ └── lib.rs
├── tests/
│ └── escrow_flow.ts
└── Anchor.toml

markdown

### Rules:

- Each instruction lives in its own file under `/instructions`.
- Shared data structures go under `/state`.
- All custom errors go in `errors.rs`.
- Events are declared in `events.rs` and emitted in every instruction.
- `lib.rs` imports only re-exported modules; no business logic should exist there.

---

## 3. 🧱 Code Style & Syntax

### 3.1 Naming

| Entity          | Convention       | Example                         |
| --------------- | ---------------- | ------------------------------- |
| Structs & Enums | PascalCase       | `EscrowState`, `DealStatus`     |
| Functions       | snake_case       | `initiate_deal`, `open_dispute` |
| Constants       | UPPER_SNAKE_CASE | `MAX_EVIDENCE_LIMIT`            |
| Modules & Files | snake_case       | `resolve.rs`, `errors.rs`       |
| Events          | PascalCase       | `DealFunded`, `DealResolved`    |

### 3.2 Formatting

- Enforce **Rustfmt** for formatting:
  ```bash
  cargo fmt --all -- --check
  Use Clippy for linting:
  ```

bash
cargo clippy --all-targets -- -D warnings
3.3 Imports
Sort imports alphabetically and group logically:

rust
use anchor*lang::prelude::*;
use anchor*spl::token::{self, Token, TokenAccount, Transfer};
use crate::state::*;
use crate::errors::_;
Never use wildcard imports (use crate::instructions::_) in production code.

4. 🧩 State & Accounts
   4.1 Account Naming
   Each PDA must be deterministic and prefixed by its purpose:

rust #[account]
pub struct EscrowState { ... }

#[account]
pub struct VaultAccount { ... }
4.2 PDA Seeds
Always use explicit seeds and document them:

rust
#[account(
init,
payer = seller,
seeds = [b"escrow", deal_id.to_be_bytes().as_ref()],
bump,
space = 8 + EscrowState::LEN
)]
pub escrow_state: Account<'info, EscrowState>,
Rule: Never derive seeds dynamically from user-provided strings.

5. 🔐 Security & Validation
   5.1 Signature Verification
   Verify all arbiters via allow-listed public keys stored in a global config PDA.

Validate ed25519 signatures for all ResolveTickets.

Reject expired or reused tickets.

5.2 Ownership and Constraints
Use Anchor constraints for ownership checks:

rust #[account(
mut,
has_one = seller @ ErrorCode::InvalidSeller,
has_one = buyer @ ErrorCode::InvalidBuyer,
constraint = escrow_state.status == DealStatus::Funded @ ErrorCode::InvalidState
)]
5.3 Transfer Safety
Use Token-2022 Transfer Hooks to enforce valid deal states before fund movement.
Funds can only move via:

release()

refund()

resolve()

5.4 Overflow & Boundary Checks
Use .checked_add() / .checked_sub() for all arithmetic.

All u64 token amounts must be bounded by price_usd_cents.

6. 📜 Error Handling
   6.1 Error Definition
   All custom errors must live in /src/errors.rs:

rust #[error_code]
pub enum ErrorCode { #[msg("Invalid state transition.")]
InvalidState, #[msg("Caller not authorized.")]
Unauthorized, #[msg("Arbiter signature invalid.")]
InvalidSignature, #[msg("Ticket expired.")]
TicketExpired,
}
6.2 Usage
Throw descriptive errors:

rust
require!(
escrow_state.status == DealStatus::Funded,
ErrorCode::InvalidState
); 7. 📣 Events & Logging
7.1 Event Declaration
All events must be declared in /src/events.rs:

rust #[event]
pub struct DealFunded {
pub deal_id: u128,
pub amount: u64,
pub timestamp: i64,
}
7.2 Event Emission
Every instruction must emit an event after a successful operation:

rust
emit!(DealFunded {
deal_id: ctx.accounts.escrow_state.deal_id,
amount: ctx.accounts.amount,
timestamp: Clock::get()?.unix_timestamp,
});
7.3 Log Format
Use msg!() only for debugging, not for state changes.

8. 🧩 Instruction Conventions
   8.1 File Template
   Each file under /instructions must follow this structure:

rust
use anchor*lang::prelude::*;
use crate::{state::_, errors::_, events::\_};

pub fn execute(ctx: Context<Initiate>, args: InitiateArgs) -> Result<()> {
let escrow = &mut ctx.accounts.escrow_state;
escrow.deal_id = args.deal_id;
escrow.status = DealStatus::Init;
emit!(DealCreated {
deal_id: args.deal_id,
seller: ctx.accounts.seller.key(),
buyer: ctx.accounts.buyer.key(),
});
Ok(())
}
8.2 Context Structs
Keep context structs lean and descriptive:

rust #[derive(Accounts)]
pub struct Initiate<'info> { #[account(mut)]
pub seller: Signer<'info>, #[account(mut)]
pub buyer: UncheckedAccount<'info>, #[account(init, payer = seller, space = 8 + EscrowState::LEN)]
pub escrow_state: Account<'info, EscrowState>,
pub system_program: Program<'info, System>,
} 9. 🧾 Documentation & Metadata
Every new or modified instruction, state, or event must include:

File Purpose
<instruction>.md Explains logic, inputs, outputs, cross-repo dependencies
<instruction>.json Schema for inputs, outputs, and dependencies

Example .md
markdown

# resolve.rs

Resolves an escrow dispute based on an AI Arbiter-signed ticket.

**Inputs:**

- `deal_id`: Unique deal identifier
- `ticket`: Signed ResolveTicket (ed25519)

**Depends on:**

- `arbiter-service` (provides signed ticket)
- `actions-server` (broadcasts transaction)

**Returns:**

- On-chain event `DealResolved`
  Example .json
  json
  Copy code
  {
  "name": "resolve",
  "inputs": {
  "deal_id": "u128",
  "ticket": "ResolveTicket"
  },
  "outputs": {
  "status": "Resolved",
  "action": "Release|Refund|Split"
  },
  "depends_on": ["arbiter-service:/resolve"],
  "provides_to": ["actions-server:/resolve"]
  }

10. 🧠 Testing Conventions
    10.1 Unit Tests
    Each instruction should have a corresponding test in /tests:

ts
Copy code
it("Funds escrow successfully", async () => {
const tx = await program.methods.fund({...}).rpc();
const state = await program.account.escrowState.fetch(dealPda);
assert.equal(state.status, { funded: {} });
});
10.2 Integration Tests
Use Solana Devnet or local validator (anchor test)

Include happy-path and failure-path cases

Validate emitted events and state transitions

10.3 Coverage
Aim for ≥ 90% instruction coverage.

Test each state transition and constraint violation.

11. 🧰 Deployment Standards
    Environment Cluster Notes
    Dev Local validator anchor test environment
    Staging Solana Testnet Pre-production
    Production Solana Mainnet-Beta Controlled by multisig

Upgrade Safety:

All upgrades via 3-of-5 multisig

48h timelock before deployment

Post-upgrade audit required (cargo audit, anchor verify)

12. 📈 Commit & Review Policy
    Commit messages follow Conventional Commits:

feat(instruction): add dispute resolver
fix(state): correct timestamp type
refactor(utils): migrate to checked_add
PR must include:

Updated .md and .json docs

Passing anchor test

cargo fmt and cargo clippy clean

13. 🧩 Cross-Repo Awareness
    When an instruction depends on external services:

Declare it in .md and .json

Examples:

resolve.rs → depends on arbiter-service

fund.rs → consumed by actions-server

DealResolved event → consumed by jobs-service

This ensures seamless interoperability across Artha Network repos.

14. 🚀 Key Principles
    Every state change must be deterministic and auditable.

Never mix business logic and I/O (no RPC calls on-chain).

Keep modules small, pure, and tested.

Document every input/output for agents and external systems.

Treat on-chain data as final source of truth.

“Trust is built on clarity.
Clarity is built on conventions.”
