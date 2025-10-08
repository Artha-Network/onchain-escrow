use anchor_lang::prelude::*;
use crate::state::escrow_state::EscrowState;
use crate::events::DealDisputed;

#[derive(Accounts)]
pub struct OpenDispute<'info> {
    pub caller: Signer<'info>,
    #[account(mut)]
    pub escrow_state: Account<'info, EscrowState>,
}

pub fn handle(ctx: Context<OpenDispute>) -> Result<()> {
    let state = &mut ctx.accounts.escrow_state;
    require!(
        ctx.accounts.caller.key() == state.seller || ctx.accounts.caller.key() == state.buyer,
        crate::errors::EscrowError::Unauthorized
    );
    state.status = crate::state::enums::DealStatus::Disputed;
    emit!(DealDisputed { deal_id: state.deal_id });
    Ok(())
}

