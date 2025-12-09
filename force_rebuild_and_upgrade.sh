#!/bin/bash
# Force a complete clean rebuild and upgrade to ensure deal_id is in PDA seeds

set -e

export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

cd /mnt/e/Artha-Network/onchain-escrow

PROGRAM_ID="HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ"

echo "=========================================="
echo "Force Rebuild and Upgrade"
echo "=========================================="
echo "Program ID: $PROGRAM_ID"
echo ""

# Step 1: Verify source
echo "Step 1: Verifying source code..."
if ! grep -q "declare_id!(\"$PROGRAM_ID\")" programs/onchain_escrow/src/lib.rs; then
    echo "ERROR: Program ID mismatch in source"
    exit 1
fi

if ! grep -q "&deal_id" programs/onchain_escrow/src/lib.rs; then
    echo "ERROR: deal_id not in PDA seeds"
    exit 1
fi

echo "✓ Source code verified"

# Step 2: Complete clean
echo ""
echo "Step 2: Complete clean..."
rm -rf target/
rm -f Cargo.lock programs/onchain_escrow/Cargo.lock
anchor clean 2>/dev/null || true

# Step 3: Restore program ID (in case Anchor changes it)
echo ""
echo "Step 3: Ensuring correct program ID..."
sed -i "s/declare_id!(\".*\");/declare_id!(\"$PROGRAM_ID\");/" programs/onchain_escrow/src/lib.rs
sed -i "s/onchain_escrow = \".*\"/onchain_escrow = \"$PROGRAM_ID\"/" Anchor.toml

# Step 4: Build
echo ""
echo "Step 4: Building..."
anchor build 2>&1 | tee /tmp/anchor_build.log

# Step 5: Check if Anchor changed program ID
echo ""
echo "Step 5: Checking if Anchor changed program ID..."
CURRENT_ID=$(grep "declare_id!" programs/onchain_escrow/src/lib.rs | sed 's/.*declare_id!("\([^"]*\)".*/\1/')

if [ "$CURRENT_ID" != "$PROGRAM_ID" ]; then
    echo "WARNING: Anchor changed program ID to $CURRENT_ID"
    echo "Restoring to $PROGRAM_ID and rebuilding..."
    sed -i "s/declare_id!(\".*\");/declare_id!(\"$PROGRAM_ID\");/" programs/onchain_escrow/src/lib.rs
    sed -i "s/onchain_escrow = \".*\"/onchain_escrow = \"$PROGRAM_ID\"/" Anchor.toml
    
    # Rebuild just the program
    cd programs/onchain_escrow
    cargo build-sbf --sbf-out-dir ../../target/deploy
    cd ../..
fi

# Step 6: Verify binary
echo ""
echo "Step 6: Verifying binary..."
if [ ! -f target/deploy/onchain_escrow.so ]; then
    echo "ERROR: Binary not found"
    exit 1
fi
echo "✓ Binary exists: $(ls -lh target/deploy/onchain_escrow.so | awk '{print $5}')"

# Step 7: Verify IDL
echo ""
echo "Step 7: Verifying IDL..."
if [ -f target/idl/onchain_escrow_program.json ]; then
    if grep -q "deal_id" target/idl/onchain_escrow_program.json; then
        echo "✓ IDL includes deal_id"
    else
        echo "ERROR: IDL missing deal_id"
        exit 1
    fi
fi

# Step 8: Upgrade
echo ""
echo "Step 8: Upgrading program..."
solana config set --url devnet

if anchor upgrade target/deploy/onchain_escrow.so --program-id "$PROGRAM_ID" --provider.cluster devnet 2>&1; then
    echo "✓ Upgrade successful"
else
    echo "Upgrade failed, trying alternative..."
    solana program deploy target/deploy/onchain_escrow.so \
        --program-id "$PROGRAM_ID" \
        --url devnet \
        --upgrade-authority /home/mbirochan/.config/solana/arthadev.json
fi

# Step 9: Verify
echo ""
echo "Step 9: Verifying upgrade..."
solana program show "$PROGRAM_ID" --url devnet | head -10

echo ""
echo "=========================================="
echo "Done! Restart actions-server and test."
echo "=========================================="

