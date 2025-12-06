# onchain-escrow Test & Deployment Summary

## Status: ✅ DEPLOYED TO DEVNET

### Deployment Details

- **Program ID**: `HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ`
- **Cluster**: Devnet
- **Deployment Signature**: `xAJq6JkzCbG5y9eoNH6gPZYPfmMcmdR1Zp3snppAJ4rhDNmPi5gp5ZxqCgHGuGVQ6SU525F2ik5vvQ7T6JNJgy2`
- **Build Status**: ✅ Successful
- **Program Binary**: `target/deploy/onchain_escrow.so`

### Configuration

- **Anchor Version**: 0.32.1
- **Cluster**: Devnet (configured in Anchor.toml)
- **Wallet**: `/home/mbirochan/.config/solana/arthadev.json`

## Commands to Run in WSL

### 1. Build the Program

```bash
cd /mnt/e/Artha-Network/onchain-escrow
anchor build
```

### 2. Run Tests

```bash
npm test
```

Or with Anchor:

```bash
anchor test --skip-local-validator
```

### 3. Deploy to Devnet

```bash
solana config set --url devnet
anchor deploy --provider.cluster devnet
```

### 4. Verify Deployment

```bash
solana program show 8HT9LQo8KAtL9kyP4q3pDqtHAc6dwmjSKcvs6XNxTQyC --url devnet
```

## Quick Script

Run the complete test and deploy script:

```bash
wsl bash /mnt/e/Artha-Network/onchain-escrow/RUN_IN_WSL.sh
```

## Program Instructions

The program supports the following instructions:

1. **initiate** - Create a new escrow
2. **fund** - Fund the escrow
3. **openDispute** - Open a dispute
4. **resolve** - Resolve a dispute (arbiter)
5. **release** - Release funds to seller
6. **refund** - Refund funds to buyer

## Test Files

Test files are located in `tests/`:

- `escrow_flow.ts` - Main test suite
- `arbiter_keypair.ts` - Arbiter keypair helper
- `mock_arbiter.ts` - Mock arbiter implementation

## Next Steps

1. ✅ Program built successfully
2. ✅ Program deployed to devnet
3. ⏳ Run tests to verify functionality
4. ⏳ Update program if needed based on test results

## Troubleshooting

If you encounter issues:

1. **Missing dependencies**: Run `npm install` in WSL
2. **Build errors**: Run `anchor clean && anchor build`
3. **Test failures**: Check that the program is deployed and the test cluster matches
4. **Deployment issues**: Verify wallet has sufficient SOL: `solana balance`

