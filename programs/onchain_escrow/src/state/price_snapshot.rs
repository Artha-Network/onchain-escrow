use anchor_lang::prelude::*;

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct PriceSnapshot {
    pub feed_id: [u8; 32],
    pub price: i64,
    pub conf: u64,
    pub slot: u64,
}

