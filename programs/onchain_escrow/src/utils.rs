use anchor_lang::prelude::*;

pub fn assert_nonzero(amount: u64) -> Result<()> {
    require!(amount > 0, crate::errors::EscrowError::InsufficientFunds);
    Ok(())
}

