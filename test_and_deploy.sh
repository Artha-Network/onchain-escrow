#!/bin/bash
set -e

cd /mnt/e/Artha-Network/onchain-escrow

echo "=========================================="
echo "Testing and Deploying onchain-escrow"
echo "=========================================="
echo ""

# Step 1: Build
echo "Step 1: Building program..."
anchor clean 2>/dev/null || true
anchor build
if [ ! -f target/deploy/onchain_escrow.so ]; then
    echo "ERROR: Build failed - onchain_escrow.so not found"
    exit 1
fi
echo "✓ Build successful"
echo ""

# Step 2: Run tests
echo "Step 2: Running tests..."
if command -v anchor &> /dev/null; then
    anchor test --skip-local-validator || npm test
else
    npm test
fi
echo "✓ Tests completed"
echo ""

# Step 3: Deploy
echo "Step 3: Deploying to devnet..."
solana config set --url devnet
solana balance
anchor deploy --provider.cluster devnet
echo "✓ Deployment complete"
echo ""

echo "=========================================="
echo "All steps completed successfully!"
echo "=========================================="


