use anchor_lang::prelude::*;

#[event]
pub struct DealInitiated {
    pub deal_id: u128,
}

#[event]
pub struct DealFunded {
    pub deal_id: u128,
    pub amount: u64,
}

#[event]
pub struct EvidenceSubmitted {
    pub deal_id: u128,
    pub cid: String,
}

#[event]
pub struct DealDisputed {
    pub deal_id: u128,
}

#[event]
pub struct DealResolved {
    pub deal_id: u128,
    pub action: String,
}

#[event]
pub struct DealReleased {
    pub deal_id: u128,
}

#[event]
pub struct DealRefunded {
    pub deal_id: u128,
}

