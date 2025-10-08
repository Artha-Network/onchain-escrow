use anchor_lang::prelude::*;
use super::price_snapshot::PriceSnapshot;
use super::enums::DealStatus;

#[account]
pub struct EscrowState {
    pub deal_id: u128,
    pub seller: Pubkey,
    pub buyer: Pubkey,
    pub arbiter_pubkey: Pubkey,
    pub price_usd_cents: u64,
    pub deposit_token_mint: Pubkey,
    pub vault_ata: Pubkey,
    pub created_at: i64,
    pub funded_at: Option<i64>,
    pub deliver_deadline: i64,
    pub dispute_deadline: i64,
    pub usd_price_snapshot: PriceSnapshot,
    pub status: DealStatus,
    pub evidence_cids: Vec<String>,
    pub rationale_cid: Option<String>,
    pub fee_bps: u16,
    pub payout_splits: Option<Vec<(Pubkey, u16)>>,
    pub nonce: u64,
}

impl EscrowState {
    pub const MAX_CID: usize = 128; // bytes
    pub const MAX_CIDS: usize = 16;

    pub fn space() -> usize {
        // 8 discriminator + fields (rough estimate for docs; adjust when building)
        8 + 16 + (32 * 4) + 8 + 32 + 32 + 8 + (1 + 8) + 8 + 8 + (32 + 8 + 8 + 8) + 1 + (4 + (Self::MAX_CIDS * (4 + Self::MAX_CID))) + (1 + 4 + Self::MAX_CID) + 2 + (1 + (4 + 32 + 2) * 4) + 8
    }
}

