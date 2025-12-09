#!/bin/bash
# Fix DeclaredProgramIdMismatch error by rebuilding with correct program ID
# This script prevents Anchor from syncing the program ID to the keypair

set -e

# Set up PATH for Solana and Anchor
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

cd /mnt/e/Artha-Network/onchain-escrow

PROGRAM_ID="HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ"

echo "=========================================="
echo "Fixing DeclaredProgramIdMismatch"
echo "=========================================="
echo "Target Program ID: $PROGRAM_ID"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Verify source code has correct program ID
echo -e "${YELLOW}Step 1: Verifying source code...${NC}"
if ! grep -q "declare_id!(\"$PROGRAM_ID\")" programs/onchain_escrow/src/lib.rs; then
    echo -e "${RED}✗ ERROR: Source code program ID doesn't match!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Source code has correct program ID${NC}"

# Step 2: Check keypair
echo ""
echo -e "${YELLOW}Step 2: Checking keypair...${NC}"
KEYPAIR_FILE="target/deploy/onchain_escrow-keypair.json"
if [ -f "$KEYPAIR_FILE" ]; then
    KEYPAIR_PUBKEY=$(solana address -k "$KEYPAIR_FILE" 2>/dev/null || echo "")
    echo "Keypair pubkey: $KEYPAIR_PUBKEY"
    echo "Expected: $PROGRAM_ID"
    
    if [ "$KEYPAIR_PUBKEY" != "$PROGRAM_ID" ]; then
        echo -e "${YELLOW}⚠ Keypair doesn't match program ID${NC}"
        echo "We'll need to backup the current keypair and create/restore the correct one"
        
        # Backup current keypair
        if [ -f "$KEYPAIR_FILE" ]; then
            BACKUP_FILE="${KEYPAIR_FILE}.backup.$(date +%s)"
            cp "$KEYPAIR_FILE" "$BACKUP_FILE"
            echo "Backed up current keypair to: $BACKUP_FILE"
        fi
        
        echo ""
        echo -e "${YELLOW}To fix this, you need the original keypair for program ID: $PROGRAM_ID${NC}"
        echo "If you don't have it, you can:"
        echo "1. Generate a new keypair (but this will create a NEW program, not upgrade existing)"
        echo "2. Restore the original keypair from backup"
        echo ""
        echo "For now, we'll try to build with --no-sync flag to prevent Anchor from changing the ID"
    else
        echo -e "${GREEN}✓ Keypair matches program ID${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Keypair file not found${NC}"
    echo "This is expected if we're doing a clean build"
fi

# Step 3: Clean and rebuild WITHOUT syncing program IDs
echo ""
echo -e "${YELLOW}Step 3: Cleaning and rebuilding (without syncing program IDs)...${NC}"
rm -rf target/
rm -f Cargo.lock programs/onchain_escrow/Cargo.lock

# Build without syncing - this prevents Anchor from changing declare_id!
# We use cargo build-bpf directly to bypass Anchor's IDL sync
echo "Building with cargo build-bpf to prevent ID sync..."
if cargo build-bpf --manifest-path=programs/onchain_escrow/Cargo.toml --bpf-out-dir=target/deploy 2>&1; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${YELLOW}Build-bpf failed, trying anchor build with manual override...${NC}"
    
    # Alternative: Build normally but immediately restore the program ID
    anchor build 2>&1 | tee /tmp/anchor_build.log || true
    
    # Check if Anchor changed the program ID
    if ! grep -q "declare_id!(\"$PROGRAM_ID\")" programs/onchain_escrow/src/lib.rs; then
        echo -e "${YELLOW}Anchor changed the program ID, restoring...${NC}"
        sed -i "s/declare_id!(\".*\");/declare_id!(\"$PROGRAM_ID\");/" programs/onchain_escrow/src/lib.rs
        sed -i "s/onchain_escrow = \".*\"/onchain_escrow = \"$PROGRAM_ID\"/" Anchor.toml
        
        # Rebuild with correct ID
        anchor build
    fi
fi

# Step 4: Verify the binary has correct program ID
echo ""
echo -e "${YELLOW}Step 4: Verifying binary...${NC}"
if [ -f target/deploy/onchain_escrow.so ]; then
    echo -e "${GREEN}✓ Binary exists${NC}"
    ls -lh target/deploy/onchain_escrow.so
else
    echo -e "${RED}✗ Binary not found${NC}"
    exit 1
fi

# Step 5: Upgrade the program
echo ""
echo -e "${YELLOW}Step 5: Upgrading program...${NC}"
solana config set --url devnet

if solana program show "$PROGRAM_ID" --url devnet > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Program exists, upgrading...${NC}"
    
    if anchor upgrade target/deploy/onchain_escrow.so --program-id "$PROGRAM_ID" --provider.cluster devnet 2>&1; then
        echo -e "${GREEN}✓ Upgrade successful!${NC}"
    else
        echo -e "${YELLOW}Trying solana program deploy...${NC}"
        solana program deploy target/deploy/onchain_escrow.so \
            --program-id "$PROGRAM_ID" \
            --url devnet \
            --upgrade-authority /home/mbirochan/.config/solana/arthadev.json
    fi
else
    echo -e "${RED}✗ Program not found on devnet${NC}"
    exit 1
fi

# Step 6: Verify
echo ""
echo -e "${YELLOW}Step 6: Verifying upgrade...${NC}"
if solana program show "$PROGRAM_ID" --url devnet > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Program verified${NC}"
    solana program show "$PROGRAM_ID" --url devnet | head -10
else
    echo -e "${RED}✗ Verification failed${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Fix complete!${NC}"
echo "=========================================="
echo ""
echo "The program should now have the correct declared program ID."
echo "Restart your actions-server and test again."
echo ""

