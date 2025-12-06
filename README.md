# On-Chain Escrow Program

The Solana program (smart contract) powering the Artha Network's escrow functionality.

## Overview
This program manages the lifecycle of escrow deals on the Solana blockchain. It handles:
- **Initiate**: Creating a new escrow account.
- **Fund**: Buyer depositing funds into the escrow vault.
- **Release**: Buyer releasing funds to the seller.
- **Refund**: Seller refunding funds to the buyer.
- **Dispute**: Arbiter intervening to resolve disputes.

## Tech Stack
- **Language**: Rust
- **Framework**: Anchor

## Setup
1. Ensure you have the Solana CLI and Anchor installed.
2. Run `anchor build` to compile the program.
3. Run `anchor test` to run the test suite.

## Key Files
- `programs/onchain-escrow/src/lib.rs`: Main program logic and instruction handlers.
- `programs/onchain-escrow/src/state.rs`: Account state definitions.
- `programs/onchain-escrow/src/instructions`: Individual instruction logic.
