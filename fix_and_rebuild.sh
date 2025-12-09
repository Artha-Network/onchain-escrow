#!/bin/bash
# Fix DeclaredProgramIdMismatch by rebuilding with correct program ID

set -e

export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

cd /mnt/e/Artha-Network/onchain-escrow

PROGRAM_ID="HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ"

echo "Fixing DeclaredProgramIdMismatch..."
echo "Program ID: $PROGRAM_ID"
echo ""

# Step 1: Ensure source has correct ID
echo "Step 1: Verifying source code..."
if ! grep -q "declare_id!(\"$PROGRAM_ID\")" programs/onchain_escrow/src/lib.rs; then
    echo "ERROR: Source code doesn't have correct program ID"
    exit 1
fi

# Step 2: Clean
echo ""
echo "Step 2: Cleaning..."
rm -rf target/
rm -f Cargo.lock programs/onchain_escrow/Cargo.lock

# Step 3: Build (Anchor will sync, but we'll fix it)
echo ""
echo "Step 3: Building (Anchor may sync program ID)..."
anchor build 2>&1 | tee /tmp/build.log || true

# Step 4: Check if Anchor changed the ID and restore if needed
echo ""
echo "Step 4: Checking if program ID was changed..."
CURRENT_ID=$(grep "declare_id!" programs/onchain_escrow/src/lib.rs | sed 's/.*declare_id!("\([^"]*\)".*/\1/')

if [ "$CURRENT_ID" != "$PROGRAM_ID" ]; then
    echo "Anchor changed program ID to: $CURRENT_ID"
    echo "Restoring to: $PROGRAM_ID"
    
    # Restore in source
    sed -i "s/declare_id!(\".*\");/declare_id!(\"$PROGRAM_ID\");/" programs/onchain_escrow/src/lib.rs
    sed -i "s/onchain_escrow = \".*\"/onchain_escrow = \"$PROGRAM_ID\"/" Anchor.toml
    
    # Rebuild just the program (not the whole workspace)
    echo "Rebuilding program with correct ID..."
    cd programs/onchain_escrow
    cargo build-sbf --sbf-out-dir ../../target/deploy 2>&1 || {
        cd ../..
        anchor build
    }
    cd ../..
else
    echo "Program ID is correct: $PROGRAM_ID"
fi

# Step 5: Verify binary exists
echo ""
echo "Step 5: Verifying binary..."
if [ ! -f target/deploy/onchain_escrow.so ]; then
    echo "ERROR: Binary not found"
    exit 1
fi
echo "Binary exists: $(ls -lh target/deploy/onchain_escrow.so | awk '{print $5}')"

# Step 6: Upgrade
echo ""
echo "Step 6: Upgrading program..."
solana config set --url devnet

if anchor upgrade target/deploy/onchain_escrow.so --program-id "$PROGRAM_ID" --provider.cluster devnet 2>&1; then
    echo "Upgrade successful!"
else
    echo "Upgrade failed, trying alternative method..."
    solana program deploy target/deploy/onchain_escrow.so \
        --program-id "$PROGRAM_ID" \
        --url devnet \
        --upgrade-authority /home/mbirochan/.config/solana/arthadev.json
fi

echo ""
echo "Done! Restart actions-server and test again."

