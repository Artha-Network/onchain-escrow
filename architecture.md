# Architecture Overview

**Goal:** Define a production‑ready architecture for a Solana dApp optimized for Anchor, Supabase, and modern frontend tooling. The focus is clarity, scalability, and maintainability for full‑stack Solana development.

---

## 1) Principles & Non‑Goals

**Principles**

- Favor **clarity over cleverness**: explicit account layouts, typed clients, thin instructions.
- **Local-first dev loop**: `solana-test-validator` + fast Anchor tests + fixture data.
- **Deterministic state**: PDAs for authority/state; avoid random account addresses.
- **Observability** from day one: logs, webhooks, tracing, dashboards.
- **Security by design**: access control, signer checks, rent-exempt storage, bounded account sizes.

**Non‑Goals**

- Not multi-chain or EVM compatible; pure Solana‑native design.
- Not a chain-agnostic abstraction. Solana‑native best practices first.

---

## 2) High‑Level System Diagram

```
[Wallet (Phantom/Backpack)]
        │ sign/approve
        ▼
[Web App (Next.js/React + @solana/web3.js + Wallet Adapter)]
        │ RPC calls / fetch program IDL
        ▼
[RPC Provider (Helius/QuickNode/Alchemy)  ←→  Devnet/Mainnet Cluster]
        │                                       │
        │ program invoke / account reads        │ on-chain program execution
        ▼                                       ▼
[Solana Program (Rust + Anchor)]         [Accounts (PDA/User/Config/SPL)]
        │
        │ events/logs
        ▼
[Indexing/Webhooks (Helius/Geyser plugin)] → [Worker/Jobs (Node/TS or Rust)] → [DB/Cache]
        │                                                       │
        └──────→ [Analytics (Flipside/Dune/SolanaFM)]  ←────────┘
```

---

## 3) Core Tooling

| Category                | Solana Tool                                   | Notes                                                                                |
| ----------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------ |
| **Program Development** | **Anchor CLI** + **Solana CLI**               | Anchor provides IDL, testing, macros; Solana CLI handles keys, validators, airdrops. |
| **Local Validator**     | `solana-test-validator`                       | Deterministic, supports forking snapshots.                                           |
| **Client SDKs**         | `@solana/web3.js`, `@coral-xyz/anchor` client | For transaction building and account querying.                                       |
| **Deployment Scripts**  | Anchor scripts (TS)                           | Versioned deployments via program IDs; guard upgrade authority.                      |

---

## 4) Folder Structure

```
/                     # root
├─ programs/          # on-chain code (Rust)
│  └─ app/            # Anchor program(s)
├─ app/               # web frontend (Next.js/React)
├─ packages/
│  ├─ client/         # typed client SDK (TS) generated from IDL
│  └─ ui/             # shared UI components
├─ infra/             # IaC, CI/CD, scripts, docker
├─ scripts/           # deploy, verify, backfill, maintenance
└─ tests/             # e2e tests hitting validator/devnet
```

---

## 5) On‑Chain Program (Rust + Anchor)

**Core Concepts**

- **Program**: stateless code; all state lives in **accounts**.
- **Accounts**: typed containers for state; rent‑exempt for persistence.
- **PDA (Program Derived Address)**: deterministic, seed‑based addresses with **program** as authority (no private key).
- **Instructions**: entry points; validate signers and account ownership; emit events for indexing.

**Example Account Struct:**

```rust
#[account]
pub struct Escrow {
    pub version: u8,
    pub initializer: Pubkey,
    pub taker: Pubkey,
    pub mint: Pubkey,
    pub amount: u64,
    pub bump: u8,
    pub status: u8,
}
```

**Events:**

```rust
#[event]
pub struct EscrowCreated { pub escrow: Pubkey, pub initializer: Pubkey, pub amount: u64 }
```

**Errors:**

```rust
#[error_code]
pub enum AppError { #[msg("Unauthorized")] Unauthorized, #[msg("InvalidState")] InvalidState }
```

---

## 6) Client & Frontend

**Client SDK**

- Generate IDL → publish a small **typed client** in `packages/client`.
- Use Anchor’s TS client for integration tests.

**Wallet Integration**

- Use **Solana Wallet Adapter** with Phantom/Backpack.
- Handle connection, disconnection, and network changes gracefully.

**Example TX Flow (TS)**

```ts
const provider = getProvider();
const program = new Program(idl, PROGRAM_ID, provider);
await program.methods
  .createEscrow(new BN(amount))
  .accounts({ escrow: escrowPda, initializer: wallet.publicKey })
  .rpc();
```

---

## 7) RPC, Indexing & Workers

**RPC Providers**

- Use **Helius/QuickNode/Alchemy** for production.
- Configure commitment levels: `processed` (speed), `confirmed` (UX), `finalized` (settlement).

**Indexing**

- Subscribe to program logs or events.
- Persist projections in a DB (Postgres/Supabase).
- Consider Geyser plugin if running your own validator.

**Workers/Jobs**

- Handle webhooks → enqueue durable jobs (e.g., BullMQ) → perform reconciliation and retries.

---

## 8) Data & Storage

- **On-chain**: critical state only.
- **Off-chain (Supabase/Postgres)**: UI projections, analytics, notifications, non-critical metadata.
- **Media/Files (MVP)**: **Supabase Storage or S3-compatible bucket**. _No Arweave/IPFS in the MVP._ Optionally store a content hash (e.g., SHA‑256) in Postgres for integrity checks and future migration planning.

**Migration note (post‑MVP):** If decentralized storage becomes a requirement, add a background job to backfill existing objects to Arweave/IPFS and persist new URIs alongside the existing bucket keys.

---

## 9) Tokens & Assets

- **SPL Tokens** for fungible assets.
- **Token Metadata** for NFTs.
- Use **Associated Token Accounts (ATA)** derived deterministically per (wallet, mint).

---

## 10) Environments

| Env     | Cluster                 | Programs              | RPC                  | Indexing               | Secrets      |
| ------- | ----------------------- | --------------------- | -------------------- | ---------------------- | ------------ |
| Local   | `solana-test-validator` | local builds          | local ws/http        | local webhook → worker | `.env.local` |
| Devnet  | `devnet`                | canary program IDs    | Helius/QuickNode dev | Helius webhooks        | Vault        |
| Mainnet | `mainnet-beta`          | versioned program IDs | prod RPC pool        | prod webhooks + DB     | Vault + KMS  |

---

## 11) Build, Test, Deploy

**Local**

```bash
solana-test-validator --reset &
solana airdrop 5
anchor build
anchor test
```

**Devnet Deploy**

```bash
anchor build
anchor deploy --provider.cluster devnet
```

**IDL Generation**

```bash
anchor idl fetch <PROGRAM_ID> > idl/app.json
```

---

## 12) CI/CD

1. Lint & typecheck.
2. Unit & integration tests.
3. Ephemeral validator for tests.
4. Build & artifact creation.
5. Devnet deploy on merge.
6. Manual approval for mainnet via multisig.

---

## 13) Security Checklist

- Enforce signer and ownership checks.
- Stable PDA seeds and stored bumps.
- Rent‑exempt accounts.
- Close unused accounts to reclaim lamports.
- Program upgrades gated by multisig.
- No unbounded vectors in state.
- Proper use of ATAs and verified mints.

---

## 14) Performance & Cost

- Minimize account writes; batch reads.
- Optimize compute unit requests.
- Compact data structures.
- Use optimistic UI with rollback on failure.

---

## 15) Observability

- Track TX success/failure, slot finality, and RPC latency.
- Use `msg!()` for on‑chain logging.
- Monitor webhook backlogs and validator errors.

---

## 16) Configuration & Secrets

`.env` frontend:

```
NEXT_PUBLIC_CLUSTER=devnet
NEXT_PUBLIC_RPC_URL=...
NEXT_PUBLIC_PROGRAM_ID=...
```

Server:

```
RPC_URL=...
WEBHOOK_SECRET=...
DATABASE_URL=postgres://...
```

---

## 17) Testing Strategy

- **Unit (Rust)**: instruction logic.
- **Anchor Tests (TS)**: local validator, edge cases.
- **E2E (Playwright/Cypress)**: wallet connect → action → confirm flow.
- **Property Tests**: validate invariants.

---

## 18) Migration & Versioning

- Increment `version` in account structs.
- Use migration instructions for layout changes.
- Maintain and tag IDLs per release.

---

## 19) Quickstart Commands

```bash
rustup default stable
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
cargo install --git https://github.com/coral-xyz/anchor avm --locked
anchor init app && cd app
anchor build && anchor test
solana config set --url https://api.devnet.solana.com
anchor deploy --provider.cluster devnet
```

---

## 20) Glossary

- **Program**: on-chain executable (smart contract) on Solana.
- **Account**: on-chain state container.
- **PDA**: program‑derived address; deterministic, program‑owned authority.
- **IDL**: interface description of program (methods, accounts, types).
- **ATA**: associated token account for a (wallet, mint).
- **Commitment**: confirmation level (`processed`, `confirmed`, `finalized`).
