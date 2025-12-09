#!/bin/bash
# Verify that the program upgrade actually took effect

set -e

export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

cd /mnt/e/Artha-Network/onchain-escrow

PROGRAM_ID="HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ"

echo "Verifying program upgrade..."
echo "Program ID: $PROGRAM_ID"
echo ""

# Check program info
echo "Program info:"
solana program show "$PROGRAM_ID" --url devnet | head -15

echo ""
echo "Checking if source has deal_id in seeds..."
if grep -q "&deal_id" programs/onchain_escrow/src/lib.rs; then
    echo "✓ Source code has deal_id in seeds"
else
    echo "✗ Source code missing deal_id in seeds!"
    exit 1
fi

echo ""
echo "Checking IDL..."
if [ -f target/idl/onchain_escrow_program.json ]; then
    if grep -q "deal_id" target/idl/onchain_escrow_program.json; then
        echo "✓ IDL includes deal_id"
    else
        echo "✗ IDL missing deal_id!"
    fi
fi

echo ""
echo "If the program is still using old PDA derivation, we need to:"
echo "1. Clean rebuild"
echo "2. Verify binary has correct code"
echo "3. Upgrade again"

