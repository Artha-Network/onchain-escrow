#!/bin/bash
# Complete test and deployment script for onchain-escrow
# Run this in WSL: wsl bash RUN_IN_WSL.sh

set -e

cd /mnt/e/Artha-Network/onchain-escrow

echo "=========================================="
echo "onchain-escrow Test & Deploy Script"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Verify environment
echo -e "${YELLOW}Step 1: Verifying environment...${NC}"
if ! command -v anchor &> /dev/null; then
    echo -e "${RED}ERROR: Anchor CLI not found. Please install Anchor.${NC}"
    exit 1
fi

if ! command -v solana &> /dev/null; then
    echo -e "${RED}ERROR: Solana CLI not found. Please install Solana CLI.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Anchor version: $(anchor --version)${NC}"
echo -e "${GREEN}✓ Solana version: $(solana --version)${NC}"
echo ""

# Step 2: Build
echo -e "${YELLOW}Step 2: Building program...${NC}"
anchor clean 2>/dev/null || true
if anchor build; then
    if [ -f target/deploy/onchain_escrow.so ]; then
        echo -e "${GREEN}✓ Build successful${NC}"
        ls -lh target/deploy/onchain_escrow.so
    else
        echo -e "${RED}✗ Build failed - onchain_escrow.so not found${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo ""

# Step 3: Run tests
echo -e "${YELLOW}Step 3: Running tests...${NC}"
if npm test; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi
echo ""

# Step 4: Deploy to devnet
echo -e "${YELLOW}Step 4: Deploying to devnet...${NC}"
solana config set --url devnet
echo "Current cluster: $(solana config get | grep 'RPC URL' | awk '{print $3}')"

BALANCE=$(solana balance --lamports | awk '{print $1}')
echo "Wallet balance: $BALANCE lamports"

if [ "$BALANCE" -lt 1000000000 ]; then
    echo -e "${YELLOW}Warning: Low balance. Requesting airdrop...${NC}"
    solana airdrop 2
fi

if anchor deploy --provider.cluster devnet; then
    echo -e "${GREEN}✓ Deployment successful${NC}"
    PROGRAM_ID=$(anchor keys list | grep onchain_escrow | awk '{print $3}')
    echo -e "${GREEN}Program ID: $PROGRAM_ID${NC}"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi
echo ""

echo "=========================================="
echo -e "${GREEN}All steps completed successfully!${NC}"
echo "=========================================="


