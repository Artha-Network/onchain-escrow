# Program ID Mismatch Issue - Root Cause & Fix

## The Problem

Your wallet address was used as the program ID instead of the intended program ID. This happened because:

**Root Cause**: The keypair file in `target/deploy/onchain_escrow-keypair.json` was actually your wallet keypair, not a dedicated program keypair.

## Why This Happens

1. **Anchor/Solana CLI uses the keypair file's pubkey as Program ID**
   - `declare_id!()` in your code is just a compile-time symbol
   - The actual Program ID comes from the keypair file used during deployment
   - Anchor doesn't enforce that `declare_id!()` matches the keypair file

2. **Common causes**:
   - Accidentally copied wallet keypair into `target/deploy/onchain_escrow-keypair.json`
   - Used the same file for both wallet and program identity
   - Manual file operations that overwrote the program keypair

## Current State

- **Code declares**: `7PNrJ5oy88u2o4DtvoRhAbnAmqZtWKvqRoURZNbmaJZi`
- **Anchor.toml has**: `7PNrJ5oy88u2o4DtvoRhAbnAmqZtWKvqRoURZNbmaJZi`
- **But deployed program ID**: Your wallet address (if keypair file was wallet)

## How to Diagnose

Run these commands to check:

```bash
# 1. Check what pubkey the keypair file has
solana-keygen pubkey programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json

# 2. Check your wallet pubkey
solana-keygen pubkey ~/.config/solana/arthadev.json

# 3. Check what's actually deployed on-chain
solana program show 7PNrJ5oy88u2o4DtvoRhAbnAmqZtWKvqRoURZNbmaJZi --url devnet
```

**If the keypair file pubkey matches your wallet pubkey → That's the problem!**

## Fix Options

### Option 1: Quick Fix (Use Current Deployed Program)

If the program is already deployed and working with your wallet as the program ID:

1. Update code to match what's actually deployed:
   ```rust
   // In lib.rs
   declare_id!("YOUR_WALLET_PUBKEY_HERE");
   ```

2. Update `Anchor.toml`:
   ```toml
   [programs.devnet]
   onchain_escrow = "YOUR_WALLET_PUBKEY_HERE"
   ```

3. Update backend config to match

4. Rebuild client/backend

**Pros**: Fast, no redeployment needed  
**Cons**: Program ID = wallet address (not ideal for security/separation)

### Option 2: Proper Fix (Recommended)

Generate a new program keypair and redeploy:

1. **Backup current keypair** (if you want to keep it):
   ```bash
   mv programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json \
      programs/onchain_escrow/target/deploy/onchain_escrow-keypair-old.json
   ```

2. **Generate new program keypair**:
   ```bash
   solana-keygen new -o programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json --no-bip39-passphrase
   ```

3. **Get the new program ID**:
   ```bash
   solana-keygen pubkey programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json
   ```

4. **Update all files with new program ID**:
   - `lib.rs`: `declare_id!("NEW_PROGRAM_ID");`
   - `Anchor.toml`: `onchain_escrow = "NEW_PROGRAM_ID"`
   - `actions-server/src/config/solana.ts`: `DEFAULT_PROGRAM_ID = "NEW_PROGRAM_ID"`

5. **Rebuild and deploy**:
   ```bash
   anchor build
   anchor deploy --provider.cluster devnet
   ```

6. **Verify deployment**:
   ```bash
   solana program show NEW_PROGRAM_ID --url devnet
   ```

## Prevention Best Practices

1. **Never copy wallet keypairs into project directories**
   - Keep wallet keys separate from program keys
   - Use different file names: `dev_wallet.json` vs `program-keypair.json`

2. **Verify before deploy**:
   ```bash
   # Always check the keypair pubkey before deploying
   solana-keygen pubkey target/deploy/onchain_escrow-keypair.json
   ```

3. **Use `.gitignore`** (already done):
   - Keypair files should never be committed
   - Your `.gitignore` already excludes `*.json` files

4. **Use scripts for keypair generation**:
   - Don't manually copy files
   - Use `solana-keygen new` or Anchor's key generation

5. **Separate concerns**:
   - Wallet keypair: For paying fees, signing transactions
   - Program keypair: For program identity (should be different!)

## Key Takeaway

**The Program ID is determined by the keypair file, NOT by `declare_id!()` in your code.**

- `declare_id!()` is just metadata in the binary
- The actual Program ID = pubkey of the keypair file used at deploy time
- Anchor will deploy whatever keypair file you give it, even if it doesn't match `declare_id!()`

## Verification Checklist

After fixing, verify:

- [ ] Keypair file exists and is NOT your wallet keypair
- [ ] `declare_id!()` matches the keypair file's pubkey
- [ ] `Anchor.toml` program ID matches
- [ ] Backend config matches
- [ ] Program deployed successfully
- [ ] On-chain program ID matches your code



