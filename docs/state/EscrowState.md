# EscrowState (Account)

Primary PDA storing escrow deal data.

- Type: Account
- Location: `programs/onchain_escrow/src/state/escrow_state.rs`

## Fields (high level)
- `deal_id: u128`
- `seller: Pubkey`
- `buyer: Pubkey`
- `arbiter_pubkey: Pubkey`
- `price_usd_cents: u64`
- `deposit_token_mint: Pubkey`
- `vault_ata: Pubkey`
- `created_at: i64`
- `funded_at: Option<i64>`
- `deliver_deadline: i64`
- `dispute_deadline: i64`
- `usd_price_snapshot: PriceSnapshot`
- `status: DealStatus`
- `evidence_cids: Vec<String>`
- `rationale_cid: Option<String>`
- `fee_bps: u16`
- `payout_splits: Option<Vec<(Pubkey, u16)>>`
- `nonce: u64`

## Seeds
- `[b"escrow", deal_id.to_be_bytes()]`

## Related
- `DealStatus` (enum)
- `PriceSnapshot`

### Updates
- v1.0.0 — Initial creation

