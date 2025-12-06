#!/bin/bash
set -e

cd /mnt/e/Artha-Network/onchain-escrow

echo "=== Deploying onchain-escrow to devnet ==="

# Check if program is built
if [ ! -f target/deploy/onchain_escrow.so ]; then
    echo "Program not built. Building now..."
    anchor build
fi

# Check Solana cluster
echo ""
echo "=== Checking Solana cluster ==="
solana config get

echo ""
echo "=== Setting cluster to devnet ==="
solana config set --url devnet

echo ""
echo "=== Checking wallet balance ==="
solana balance

echo ""
echo "=== Deploying program ==="
anchor deploy --provider.cluster devnet

echo ""
echo "=== Deployment complete ==="
echo "Program ID: $(anchor keys list | grep onchain_escrow | awk '{print $3}')"


