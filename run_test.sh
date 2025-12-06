#!/bin/bash
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
source $HOME/.cargo/env
cd programs/onchain_escrow && cargo-build-sbf
cd ../..
anchor test --skip-build
