use anchor_lang::prelude::*;
use crate::state::escrow_state::EscrowState;
use crate::events::DealRefunded;

#[derive(Accounts)]
pub struct Refund<'info> {
    #[account(mut)]
    pub seller: Signer<'info>,
    #[account(mut)]
    pub escrow_state: Account<'info, EscrowState>,
}

pub fn handle(ctx: Context<Refund>) -> Result<()> {
    let state = &mut ctx.accounts.escrow_state;
    state.status = crate::state::enums::DealStatus::Refunded;
    emit!(DealRefunded { deal_id: state.deal_id });
    Ok(())
}

