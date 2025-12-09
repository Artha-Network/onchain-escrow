#!/bin/bash
# Simple deployment script for on-chain escrow program
# Uses the keypair in target/deploy/onchain_escrow-keypair.json

set -e

echo "=========================================="
echo "Deploying On-Chain Escrow Program"
echo "=========================================="
echo ""

# Set up PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Verify tools
if ! command -v anchor &> /dev/null; then
    echo "❌ Error: anchor command not found"
    exit 1
fi

if ! command -v solana &> /dev/null; then
    echo "❌ Error: solana command not found"
    exit 1
fi

# Check cluster
echo "Checking cluster configuration..."
solana config set --url devnet 2>/dev/null || true
echo ""

# Check balance
echo "Checking wallet balance..."
BALANCE_OUTPUT=$(solana balance 2>&1)
echo "$BALANCE_OUTPUT"
BALANCE=$(echo "$BALANCE_OUTPUT" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
if [ -n "$BALANCE" ]; then
    BALANCE_CHECK=$(echo "$BALANCE" | awk '{if ($1 < 2.0) print "low"; else print "ok"}')
    if [ "$BALANCE_CHECK" = "low" ]; then
        echo "⚠️  Low balance. Requesting airdrop..."
        solana airdrop 2
        sleep 5
    fi
fi
echo ""

# Clean and build
echo "Cleaning previous build..."
anchor clean

echo ""
echo "Building program..."
anchor build

# Get program ID from keypair
echo ""
echo "Getting program ID from keypair..."
PROGRAM_ID=$(solana address -k target/deploy/onchain_escrow-keypair.json)
echo "Program ID: $PROGRAM_ID"
echo ""

# Deploy
echo "Deploying program..."
anchor deploy

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Program ID: $PROGRAM_ID"
echo "PDA Structure: [\"escrow\", deal_id_bytes]"
echo ""
echo "⚠️  IMPORTANT: Update actions-server/src/config/solana.ts with this program ID:"
echo "   DEFAULT_PROGRAM_ID = \"$PROGRAM_ID\""
echo ""



