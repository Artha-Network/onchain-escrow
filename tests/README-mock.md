# Local mock integration tests

This folder contains helpers to test off-chain parts that interact with the on-chain program.

## Prerequisites

- Run the Anchor local validator (`anchor test` or `solana-test-validator`) and ensure the program is built.
- Start the mock arbiter service (see `arbiter-service/mock-arbiter/README.md`).

## Workflow

1. **Run Anchor tests with mock arbiter integration:**

```bash
# From onchain-escrow directory
anchor test
```

The test `"end-to-end dispute flow with mock arbiter"` demonstrates the full escrow lifecycle:

- `initiate` → `fund` → `open_dispute` → `resolve` → `refund`

2. **Run mock arbiter service (optional for off-chain ticket testing):**

```bash
cd arbiter-service/mock-arbiter
pnpm install
pnpm dev
```

Use `tests/mock_arbiter.ts` helper to fetch and verify signed tickets from the mock service.

## Key Files

- `tests/arbiter_keypair.ts` - Shared deterministic keypair for testing
- `tests/mock_arbiter.ts` - Helper to request/verify tickets from mock service
- `tests/escrow_flow.ts` - Complete end-to-end Anchor tests including dispute resolution

## Integration Notes

- The tests use a **deterministic mock arbiter keypair** (same seed across mock service and Anchor tests) for reproducible testing.
- The current on-chain `resolve` instruction expects the arbiter as a direct signer. The mock arbiter service provides signed tickets for future off-chain verification flows.
- For production, consider implementing on-chain ed25519 signature verification to accept arbiter tickets without requiring the arbiter as a transaction signer.

## Supabase Integration

For full off-chain integration testing, run Supabase locally:

```bash
# Install Supabase CLI: https://supabase.com/docs/guides/cli
supabase start
```

See the actions-server and web-app READMEs for Supabase setup and RLS policies.
