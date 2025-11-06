use anchor_lang::prelude::*;

use crate::{EscrowError, DealDisputed, EscrowStatus, EscrowState};

#[derive(Accounts)]
pub struct OpenDispute<'info> {
    pub caller: Signer<'info>,
    #[account(
        mut,
        constraint = escrow_state.status == EscrowStatus::Funded @ EscrowError::InvalidState,
    )]
    pub escrow_state: Account<'info, EscrowState>,
}

pub fn handle(ctx: Context<OpenDispute>) -> Result<()> {
    let state = &mut ctx.accounts.escrow_state;

    require!(
        ctx.accounts.caller.key() == state.seller || ctx.accounts.caller.key() == state.buyer,
        EscrowError::Unauthorized
    );

    if state.dispute_by > 0 {
        let now = Clock::get()?.unix_timestamp;
        require!(now <= state.dispute_by, EscrowError::DeadlinePassed);
    }

    state.status = EscrowStatus::Disputed;

    emit!(DealDisputed { by: ctx.accounts.caller.key() });

    Ok(())
}
