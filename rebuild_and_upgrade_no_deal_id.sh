#!/bin/bash
# Rebuild and upgrade program without deal_id in PDA seeds

set -e

export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

cd /mnt/e/Artha-Network/onchain-escrow

PROGRAM_ID="HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ"

echo "=========================================="
echo "Rebuilding without deal_id in PDA seeds"
echo "=========================================="
echo "Program ID: $PROGRAM_ID"
echo ""

# Step 1: Verify source code
echo "Step 1: Verifying source code..."
if ! grep -q "declare_id!(\"$PROGRAM_ID\")" programs/onchain_escrow/src/lib.rs; then
    echo "ERROR: Program ID mismatch"
    exit 1
fi

if grep -q "&deal_id" programs/onchain_escrow/src/lib.rs | grep -v "//"; then
    echo "ERROR: deal_id still in PDA seeds!"
    exit 1
fi

echo "✓ Source code verified - deal_id removed from PDA seeds"

# Step 2: Clean and rebuild
echo ""
echo "Step 2: Cleaning and rebuilding..."
rm -rf target/
rm -f Cargo.lock programs/onchain_escrow/Cargo.lock

anchor build 2>&1 | tee /tmp/build.log

# Step 3: Verify binary
echo ""
echo "Step 3: Verifying binary..."
if [ ! -f target/deploy/onchain_escrow.so ]; then
    echo "ERROR: Binary not found"
    exit 1
fi
echo "✓ Binary exists"

# Step 4: Upgrade
echo ""
echo "Step 4: Upgrading program..."
solana config set --url devnet

anchor upgrade target/deploy/onchain_escrow.so --program-id "$PROGRAM_ID" --provider.cluster devnet

echo ""
echo "=========================================="
echo "Done! Restart actions-server and test."
echo "=========================================="

