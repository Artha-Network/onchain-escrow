import * as anchor from "@coral-xyz/anchor";

// Same deterministic seed as in mock arbiter for testing
const MOCK_SEED = new Uint8Array([
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
]);

export function getMockArbiterKeypair() {
  // Convert ed25519 seed to Solana Keypair
  return anchor.web3.Keypair.fromSeed(MOCK_SEED);
}