use anchor_lang::prelude::*;

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, Debug)]
pub enum DealStatus {
    Init,
    Funded,
    Delivered,
    Disputed,
    Resolved,
    Released,
    Refunded,
}

