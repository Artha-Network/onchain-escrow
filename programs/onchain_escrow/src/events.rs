use anchor_lang::prelude::*;

#[event]
pub struct DealInitiated {
    pub seller: Pubkey,
    pub buyer: Pubkey,
    pub mint: Pubkey,
    pub amount: u64,
}

#[event]
pub struct DealFunded {
    pub buyer: Pubkey,
    pub amount: u64,
}

#[event]
pub struct DealDisputed {
    pub by: Pubkey,
}

#[event]
pub struct DealResolved {
    pub verdict: u8,
}

#[event]
pub struct DealReleased {
    pub amount: u64,
}

#[event]
pub struct DealRefunded {
    pub amount: u64,
}
