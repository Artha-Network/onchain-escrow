#!/bin/bash
# Fix DeclaredProgramIdMismatch by rebuilding with correct program ID sync

set -e

cd /mnt/e/Artha-Network/onchain-escrow

# Set up PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

echo "=========================================="
echo "Fixing Program ID Mismatch"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Get program ID from keypair
echo -e "${YELLOW}Step 1: Getting program ID from keypair...${NC}"
KEYPAIR_FILE="target/deploy/onchain_escrow-keypair.json"

if [ ! -f "$KEYPAIR_FILE" ]; then
    echo -e "${RED}✗ Keypair file not found: $KEYPAIR_FILE${NC}"
    echo "Creating keypair directory..."
    mkdir -p target/deploy
    echo "You may need to generate a new keypair or restore from backup"
    exit 1
fi

PROGRAM_ID=$(solana address -k "$KEYPAIR_FILE")
echo -e "${GREEN}✓ Program ID from keypair: $PROGRAM_ID${NC}"
echo ""

# Step 2: Update declare_id! in lib.rs
echo -e "${YELLOW}Step 2: Updating declare_id! in lib.rs...${NC}"
LIB_RS="programs/onchain_escrow/src/lib.rs"
CURRENT_DECLARE=$(grep -o 'declare_id!("[^"]*")' "$LIB_RS" | head -1)
echo "Current: $CURRENT_DECLARE"

if [[ "$CURRENT_DECLARE" == *"$PROGRAM_ID"* ]]; then
    echo -e "${GREEN}✓ declare_id! already matches keypair${NC}"
else
    echo "Updating to match keypair..."
    sed -i "s/declare_id!(\"[^\"]*\");/declare_id!(\"$PROGRAM_ID\");/" "$LIB_RS"
    echo -e "${GREEN}✓ Updated declare_id! to $PROGRAM_ID${NC}"
fi
echo ""

# Step 3: Update Anchor.toml
echo -e "${YELLOW}Step 3: Updating Anchor.toml...${NC}"
CURRENT_ANCHOR=$(grep -o 'onchain_escrow = "[^"]*"' Anchor.toml | head -1)
echo "Current: $CURRENT_ANCHOR"

if [[ "$CURRENT_ANCHOR" == *"$PROGRAM_ID"* ]]; then
    echo -e "${GREEN}✓ Anchor.toml already matches keypair${NC}"
else
    echo "Updating to match keypair..."
    sed -i "s/onchain_escrow = \"[^\"]*\"/onchain_escrow = \"$PROGRAM_ID\"/" Anchor.toml
    echo -e "${GREEN}✓ Updated Anchor.toml to $PROGRAM_ID${NC}"
fi
echo ""

# Step 4: Clean and rebuild
echo -e "${YELLOW}Step 4: Cleaning and rebuilding...${NC}"
anchor clean
echo "Building..."
if anchor build; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo ""

# Step 5: Verify
echo -e "${YELLOW}Step 5: Verifying program ID consistency...${NC}"
BUILT_DECLARE=$(grep -o 'declare_id!("[^"]*")' "$LIB_RS" | head -1 | grep -o '"[^"]*"' | tr -d '"')
BUILT_ANCHOR=$(grep -o 'onchain_escrow = "[^"]*"' Anchor.toml | head -1 | grep -o '"[^"]*"' | tr -d '"')

echo "Keypair Program ID: $PROGRAM_ID"
echo "lib.rs declare_id!: $BUILT_DECLARE"
echo "Anchor.toml: $BUILT_ANCHOR"

if [ "$PROGRAM_ID" == "$BUILT_DECLARE" ] && [ "$PROGRAM_ID" == "$BUILT_ANCHOR" ]; then
    echo -e "${GREEN}✓ All program IDs match!${NC}"
else
    echo -e "${RED}✗ Program IDs don't match${NC}"
    exit 1
fi
echo ""

echo "=========================================="
echo -e "${GREEN}✅ Fix Complete!${NC}"
echo "=========================================="
echo ""
echo "Program ID: $PROGRAM_ID"
echo ""
echo "⚠️  IMPORTANT: Update actions-server/src/config/solana.ts with this program ID:"
echo "   DEFAULT_PROGRAM_ID = \"$PROGRAM_ID\""
echo ""

