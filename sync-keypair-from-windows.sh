#!/bin/bash
# Copy keypair from Windows to WSL

set -e

WINDOWS_KEYPAIR="/mnt/e/Artha-Network/onchain-escrow/programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json"
WSL_KEYPAIR="target/deploy/onchain_escrow-keypair.json"

echo "Syncing keypair from Windows to WSL..."
echo ""

if [ ! -f "$WINDOWS_KEYPAIR" ]; then
    echo "❌ ERROR: Windows keypair not found at: $WINDOWS_KEYPAIR"
    exit 1
fi

# Create directory if it doesn't exist
mkdir -p target/deploy

# Backup existing if it exists
if [ -f "$WSL_KEYPAIR" ]; then
    echo "Backing up existing keypair..."
    cp "$WSL_KEYPAIR" "${WSL_KEYPAIR}.backup"
    echo "✓ Backed up to ${WSL_KEYPAIR}.backup"
fi

# Copy from Windows
echo "Copying keypair from Windows..."
cp "$WINDOWS_KEYPAIR" "$WSL_KEYPAIR"
echo "✓ Copied to $WSL_KEYPAIR"

# Verify
if command -v solana-keygen &> /dev/null; then
    PUBKEY=$(solana-keygen pubkey "$WSL_KEYPAIR" 2>/dev/null)
    echo "✓ Keypair pubkey: $PUBKEY"
    
    # Check if it matches lib.rs
    PROGRAM_ID=$(grep -oP 'declare_id!\("\K[^"]+' programs/onchain_escrow/src/lib.rs | head -1)
    if [ "$PUBKEY" == "$PROGRAM_ID" ]; then
        echo "✓ Keypair matches program ID in lib.rs"
    else
        echo "⚠️  WARNING: Keypair pubkey doesn't match program ID!"
        echo "   Keypair: $PUBKEY"
        echo "   Program ID: $PROGRAM_ID"
    fi
fi

echo ""
echo "✅ Keypair synced successfully!"



