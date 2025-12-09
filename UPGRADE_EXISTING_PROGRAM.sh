#!/bin/bash
# Upgrade existing program with program ID HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ
# This script upgrades the existing program instead of creating a new one

set -e

# Set up PATH for Solana and Anchor
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

cd /mnt/e/Artha-Network/onchain-escrow

PROGRAM_ID="HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ"

echo "=========================================="
echo "Upgrading Existing Program"
echo "=========================================="
echo "Program ID: $PROGRAM_ID"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Verify source code
echo -e "${YELLOW}Step 1: Verifying source code...${NC}"
if ! grep -q "declare_id!(\"$PROGRAM_ID\")" programs/onchain_escrow/src/lib.rs; then
    echo -e "${RED}✗ ERROR: Source code program ID doesn't match!${NC}"
    echo "Expected: $PROGRAM_ID"
    grep "declare_id!" programs/onchain_escrow/src/lib.rs
    exit 1
fi
echo -e "${GREEN}✓ Source code has correct program ID${NC}"

if ! grep -q "&deal_id" programs/onchain_escrow/src/lib.rs; then
    echo -e "${RED}✗ ERROR: Source code doesn't include deal_id in PDA seeds!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Source code includes deal_id in PDA seeds${NC}"

# Step 2: Clean and rebuild
echo ""
echo -e "${YELLOW}Step 2: Cleaning and rebuilding...${NC}"
rm -rf target/
rm -f Cargo.lock programs/onchain_escrow/Cargo.lock

if anchor build; then
    if [ -f target/deploy/onchain_escrow.so ]; then
        echo -e "${GREEN}✓ Build successful${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# Step 3: Verify IDL
echo ""
echo -e "${YELLOW}Step 3: Verifying IDL...${NC}"
if [ -f target/idl/onchain_escrow_program.json ]; then
    if grep -q "deal_id" target/idl/onchain_escrow_program.json; then
        echo -e "${GREEN}✓ IDL includes deal_id${NC}"
    else
        echo -e "${RED}✗ IDL missing deal_id${NC}"
        exit 1
    fi
fi

# Step 4: Set cluster
echo ""
echo -e "${YELLOW}Step 4: Setting cluster...${NC}"
solana config set --url devnet

# Step 5: Check program exists
echo ""
echo -e "${YELLOW}Step 5: Checking if program exists...${NC}"
if solana program show "$PROGRAM_ID" --url devnet > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Program exists on devnet${NC}"
    solana program show "$PROGRAM_ID" --url devnet | head -10
    
    # Check upgrade authority
    UPGRADE_AUTH=$(solana program show "$PROGRAM_ID" --url devnet 2>/dev/null | grep "Upgrade Authority" | awk '{print $3}' || echo "")
    WALLET=$(solana address 2>/dev/null || echo "")
    
    if [ -n "$UPGRADE_AUTH" ] && [ "$UPGRADE_AUTH" != "$WALLET" ] && [ "$UPGRADE_AUTH" != "<no upgrade authority>" ]; then
        echo -e "${RED}✗ ERROR: Upgrade authority mismatch!${NC}"
        echo "  Program upgrade authority: $UPGRADE_AUTH"
        echo "  Current wallet: $WALLET"
        echo "  You don't have permission to upgrade this program"
        exit 1
    fi
    echo -e "${GREEN}✓ Upgrade authority verified${NC}"
else
    echo -e "${RED}✗ Program $PROGRAM_ID not found on devnet${NC}"
    echo "Cannot upgrade - program doesn't exist"
    exit 1
fi

# Step 6: Check balance
echo ""
echo -e "${YELLOW}Step 6: Checking wallet balance...${NC}"
BALANCE=$(solana balance --lamports 2>/dev/null | awk '{print $1}' || echo "0")
echo "Balance: $BALANCE lamports"

if [ "$BALANCE" -lt 1000000000 ]; then
    echo -e "${YELLOW}Requesting airdrop...${NC}"
    solana airdrop 2 || echo "Airdrop failed"
fi

# Step 7: Upgrade program
echo ""
echo -e "${YELLOW}Step 7: Upgrading program...${NC}"
echo "This will upgrade the existing program at $PROGRAM_ID"

# Try anchor upgrade first
if anchor upgrade target/deploy/onchain_escrow.so --program-id "$PROGRAM_ID" --provider.cluster devnet 2>&1; then
    echo -e "${GREEN}✓ Upgrade successful!${NC}"
else
    echo -e "${YELLOW}Anchor upgrade failed, trying solana program deploy...${NC}"
    
    # Fallback to solana program deploy
    if solana program deploy target/deploy/onchain_escrow.so \
        --program-id "$PROGRAM_ID" \
        --url devnet \
        --upgrade-authority /home/mbirochan/.config/solana/arthadev.json 2>&1; then
        echo -e "${GREEN}✓ Upgrade successful using solana program deploy!${NC}"
    else
        echo -e "${RED}✗ Upgrade failed${NC}"
        exit 1
    fi
fi

# Step 8: Verify upgrade
echo ""
echo -e "${YELLOW}Step 8: Verifying upgrade...${NC}"
if solana program show "$PROGRAM_ID" --url devnet > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Program verified on devnet${NC}"
    solana program show "$PROGRAM_ID" --url devnet | head -10
else
    echo -e "${RED}✗ Could not verify program${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Upgrade complete!${NC}"
echo "=========================================="
echo ""
echo "Program ID: $PROGRAM_ID"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart actions-server"
echo "2. Test creating a new deal"
echo "3. Verify no PDA mismatch errors"
echo ""

