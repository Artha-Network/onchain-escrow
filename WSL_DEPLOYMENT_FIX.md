# WSL Deployment Fix

## Problem

The deployment is trying to use the old program ID `HwPkmjvQMHzRuyUYWcqibNQu4KFMLTqqMYFfgHhZvtBT` instead of the new one `B1a1oejNg8uWz7USuuFSqmRQRUSZ95kk2e4PzRZ7Uti4`.

This happens because the keypair file in WSL doesn't match the updated program ID in the code.

## Solution

### Option 1: Sync Keypair from Windows (Recommended)

Run this in WSL:

```bash
cd /mnt/e/Artha-Network/onchain-escrow
chmod +x sync-keypair-from-windows.sh
./sync-keypair-from-windows.sh
```

This will copy the correct keypair from Windows to WSL.

### Option 2: Manual Copy

```bash
# In WSL
cd /mnt/e/Artha-Network/onchain-escrow
mkdir -p target/deploy
cp programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json \
   target/deploy/onchain_escrow-keypair.json
```

### Option 3: Verify and Fix Configuration

Run the diagnostic script:

```bash
chmod +x fix-wsl-deployment.sh
./fix-wsl-deployment.sh
```

## After Syncing Keypair

1. **Clean build artifacts:**
   ```bash
   anchor clean
   ```

2. **Rebuild:**
   ```bash
   anchor build
   ```

3. **Verify the program ID matches:**
   ```bash
   grep declare_id programs/onchain_escrow/src/lib.rs
   solana-keygen pubkey target/deploy/onchain_escrow-keypair.json
   ```
   
   Both should show: `B1a1oejNg8uWz7USuuFSqmRQRUSZ95kk2e4PzRZ7Uti4`

4. **Request airdrop for the new program ID:**
   ```bash
   solana airdrop 2 B1a1oejNg8uWz7USuuFSqmRQRUSZ95kk2e4PzRZ7Uti4 --url devnet
   ```

5. **Deploy:**
   ```bash
   anchor deploy --provider.cluster devnet
   ```

## Why This Happened

- The keypair file in WSL (`target/deploy/onchain_escrow-keypair.json`) still had the old program ID
- Anchor uses the keypair file's pubkey as the program ID, not what's in `declare_id!()`
- When you updated the code on Windows, the WSL keypair file wasn't updated

## Prevention

Always sync keypair files between Windows and WSL, or use the same keypair file location that's accessible from both.



