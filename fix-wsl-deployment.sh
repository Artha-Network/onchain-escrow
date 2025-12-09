#!/bin/bash
# Fix WSL deployment - ensure keypair matches program ID

set -e

echo "========================================"
echo "Fixing WSL Deployment Configuration"
echo "========================================"
echo ""

# Get the current program ID from lib.rs
PROGRAM_ID=$(grep -oP 'declare_id!\("\K[^"]+' programs/onchain_escrow/src/lib.rs | head -1)

if [ -z "$PROGRAM_ID" ]; then
    echo "❌ ERROR: Could not extract program ID from lib.rs"
    exit 1
fi

echo "Program ID from lib.rs: $PROGRAM_ID"
echo ""

# Check if keypair file exists
KEYPAIR_FILE="target/deploy/onchain_escrow-keypair.json"
if [ -f "$KEYPAIR_FILE" ]; then
    echo "✓ Keypair file exists: $KEYPAIR_FILE"
    
    # Get pubkey from keypair file
    if command -v solana-keygen &> /dev/null; then
        KEYPAIR_PUBKEY=$(solana-keygen pubkey "$KEYPAIR_FILE" 2>/dev/null || echo "")
        if [ -n "$KEYPAIR_PUBKEY" ]; then
            echo "Keypair pubkey: $KEYPAIR_PUBKEY"
            
            if [ "$KEYPAIR_PUBKEY" != "$PROGRAM_ID" ]; then
                echo "⚠️  MISMATCH: Keypair pubkey doesn't match program ID!"
                echo "   Keypair: $KEYPAIR_PUBKEY"
                echo "   Program ID: $PROGRAM_ID"
                echo ""
                echo "Backing up old keypair..."
                mv "$KEYPAIR_FILE" "${KEYPAIR_FILE}.old"
                echo "✓ Backed up to ${KEYPAIR_FILE}.old"
                echo ""
                echo "❌ You need to copy the correct keypair file from Windows:"
                echo "   From: E:\\Artha-Network\\onchain-escrow\\programs\\onchain_escrow\\target\\deploy\\onchain_escrow-keypair.json"
                echo "   To:   /mnt/e/Artha-Network/onchain-escrow/target/deploy/onchain_escrow-keypair.json"
                echo ""
                echo "Or generate a new one that matches the program ID."
                exit 1
            else
                echo "✓ Keypair matches program ID"
            fi
        fi
    else
        echo "⚠️  solana-keygen not found, cannot verify keypair"
    fi
else
    echo "⚠️  Keypair file not found: $KEYPAIR_FILE"
    echo "   You need to copy it from Windows or generate a new one"
    exit 1
fi

echo ""
echo "Verifying Anchor.toml..."
ANCHOR_ID=$(grep -oP 'onchain_escrow = "\K[^"]+' Anchor.toml | head -1)
if [ "$ANCHOR_ID" != "$PROGRAM_ID" ]; then
    echo "⚠️  Anchor.toml mismatch! Updating..."
    sed -i "s/onchain_escrow = \".*\"/onchain_escrow = \"$PROGRAM_ID\"/" Anchor.toml
    echo "✓ Updated Anchor.toml"
else
    echo "✓ Anchor.toml matches"
fi

echo ""
echo "========================================"
echo "Configuration verified!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Clean build: anchor clean"
echo "2. Build: anchor build"
echo "3. Verify program ID matches: grep declare_id programs/onchain_escrow/src/lib.rs"
echo "4. Deploy: anchor deploy --provider.cluster devnet"
echo ""



