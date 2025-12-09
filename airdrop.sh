#!/bin/bash
# Request SOL airdrop for devnet

export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

cd /mnt/e/Artha-Network/onchain-escrow

echo "Setting cluster to devnet..."
solana config set --url devnet

echo ""
echo "Current balance:"
solana balance

echo ""
echo "Requesting 5 SOL airdrop..."
solana airdrop 5

echo ""
echo "New balance:"
solana balance

