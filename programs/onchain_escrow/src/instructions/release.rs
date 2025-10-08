use anchor_lang::prelude::*;
use crate::state::escrow_state::EscrowState;
use crate::events::DealReleased;

#[derive(Accounts)]
pub struct Release<'info> {
    #[account(mut)]
    pub buyer: Signer<'info>,
    #[account(mut, has_one = buyer)]
    pub escrow_state: Account<'info, EscrowState>,
}

pub fn handle(ctx: Context<Release>) -> Result<()> {
    let state = &mut ctx.accounts.escrow_state;
    state.status = crate::state::enums::DealStatus::Released;
    emit!(DealReleased { deal_id: state.deal_id });
    Ok(())
}

