use anchor_lang::prelude::*;
use crate::EscrowError;

pub const VERDICT_RELEASE: u8 = 1;
pub const VERDICT_REFUND: u8 = 2;

pub fn assert_nonzero(amount: u64) -> Result<()> {
    require!(amount > 0, EscrowError::InsufficientFunds);
    Ok(())
}

