use anchor_lang::prelude::*;
use crate::state::escrow_state::EscrowState;
use crate::events::DealFunded;
use crate::errors::EscrowError;

#[derive(Accounts)]
pub struct Fund<'info> {
    #[account(mut)]
    pub buyer: Signer<'info>,
    #[account(mut, has_one = buyer)]
    pub escrow_state: Account<'info, EscrowState>,
}

pub fn handle(ctx: Context<Fund>, amount: u64) -> Result<()> {
    require!(amount > 0, EscrowError::InsufficientFunds);
    let state = &mut ctx.accounts.escrow_state;
    state.funded_at = Some(Clock::get()?.unix_timestamp);
    state.status = crate::state::enums::DealStatus::Funded;
    emit!(DealFunded { deal_id: state.deal_id, amount });
    Ok(())
}

