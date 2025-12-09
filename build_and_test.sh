#!/bin/bash
set -e

cd /mnt/e/Artha-Network/onchain-escrow

echo "=== Checking Anchor version ==="
anchor --version || echo "Anchor not found"

echo ""
echo "=== Checking Solana version ==="
solana --version || echo "Solana not found"

echo ""
echo "=== Cleaning previous build ==="
anchor clean || true

echo ""
echo "=== Building program ==="
anchor build

echo ""
echo "=== Checking build output ==="
if [ -f target/deploy/onchain_escrow.so ]; then
    echo "✓ Build successful - onchain_escrow.so exists"
    ls -lh target/deploy/onchain_escrow.so
else
    echo "✗ Build failed - onchain_escrow.so not found"
    exit 1
fi

echo ""
echo "=== Running tests ==="
anchor test --skip-local-validator || npm test

echo ""
echo "=== Build and test complete ==="




