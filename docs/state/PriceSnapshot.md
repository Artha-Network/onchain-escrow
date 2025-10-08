# PriceSnapshot (Struct)

Captures USD price snapshot data (e.g., from Pyth) at funding.

- Type: Struct
- Location: `programs/onchain_escrow/src/state/price_snapshot.rs`

## Fields
- `feed_id: [u8; 32]`
- `price: i64`
- `conf: u64`
- `slot: u64`

### Updates
- v1.0.0 — Initial creation

