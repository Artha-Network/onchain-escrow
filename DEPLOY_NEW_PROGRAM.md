# New Program Deployment Guide

## Summary

A new program keypair has been generated and all configuration files have been updated with the new program ID.

## New Program Details

- **Program ID**: `7PNrJ5oy88u2o4DtvoRhAbnAmqZtWKvqRoURZNbmaJZi`
- **Keypair Location**: `programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json`
- **Cluster**: Devnet
- **Upgradable**: Yes (Anchor programs are upgradable by default)

## Files Updated

### On-Chain Program
- ✅ `programs/onchain_escrow/src/lib.rs` - Updated `declare_id!`
- ✅ `Anchor.toml` - Updated program ID

### Backend
- ✅ `actions-server/src/config/solana.ts` - Updated `DEFAULT_PROGRAM_ID`

### Frontend
- ✅ No changes needed (uses backend API)

### AI Arbitration
- ✅ No changes needed (doesn't use program ID directly)

## Deployment Steps

### 1. Request Airdrop

The program keypair needs SOL for deployment. Request an airdrop:

```bash
# Using Solana CLI (if available)
solana airdrop 2 7PNrJ5oy88u2o4DtvoRhAbnAmqZtWKvqRoURZNbmaJZi --url devnet

# Or using curl
curl -X POST "https://api.devnet.solana.com" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"requestAirdrop",
    "params":["7PNrJ5oy88u2o4DtvoRhAbnAmqZtWKvqRoURZNbmaJZi", 2000000000]
  }'
```

### 2. Build the Program

```bash
cd onchain-escrow
anchor build
```

This will:
- Compile the Rust program
- Generate the IDL
- Create the `.so` binary in `target/deploy/`

### 3. Deploy the Program

```bash
anchor deploy --provider.cluster devnet
```

This will:
- Deploy the program to devnet
- Make it upgradable (default behavior)
- Set the upgrade authority to your wallet

### 4. Verify Deployment

```bash
solana program show 7PNrJ5oy88u2o4DtvoRhAbnAmqZtWKvqRoURZNbmaJZi --url devnet
```

You should see:
- Program Data Account
- Upgrade Authority
- Program ID matches

## Backup Files

The following files have been backed up:
- `programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json.backup` (old keypair)
- `programs/onchain_escrow/target/deploy/onchain_escrow.so.backup` (old binary)

## Next Steps

1. **Request airdrop** for the new program ID
2. **Build the program** using `anchor build`
3. **Deploy the program** using `anchor deploy`
4. **Restart the backend server** to pick up the new program ID
5. **Test creating a new deal** to verify everything works

## Important Notes

- The program is **upgradable by default** when deployed with Anchor
- The upgrade authority is set to your wallet (from `~/.config/solana/arthadev.json`)
- All existing deals created with the old program ID will not work with the new program
- You may need to migrate existing deals or keep the old program running for legacy deals

## Troubleshooting

### If deployment fails due to insufficient funds:
- Request more airdrop: `solana airdrop 2 <program-id> --url devnet`

### If you get "Program account does not exist":
- This is expected for a new program ID
- Use `anchor deploy` (not `anchor upgrade`) for the first deployment

### If you need to upgrade later:
```bash
anchor upgrade target/deploy/onchain_escrow.so --program-id 7PNrJ5oy88u2o4DtvoRhAbnAmqZtWKvqRoURZNbmaJZi --provider.cluster devnet
```

