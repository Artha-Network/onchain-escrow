use anchor_lang::prelude::*;

use crate::{EscrowError, DealResolved, EscrowStatus, EscrowState, VERDICT_RELEASE, VERDICT_REFUND};

#[derive(Accounts)]
pub struct Resolve<'info> {
    pub arbiter: Signer<'info>,
    #[account(
        mut,
        constraint = escrow_state.arbiter == arbiter.key() @ EscrowError::Unauthorized,
        constraint = matches!(escrow_state.status, EscrowStatus::Funded | EscrowStatus::Disputed) @ EscrowError::InvalidState,
    )]
    pub escrow_state: Account<'info, EscrowState>,
}

pub fn handle(ctx: Context<Resolve>, verdict: u8) -> Result<()> {
    require!(
        verdict == VERDICT_RELEASE || verdict == VERDICT_REFUND,
        EscrowError::InvalidState
    );

    let state = &mut ctx.accounts.escrow_state;
    state.status = EscrowStatus::Resolved;
    state.nonce = state
        .nonce
        .checked_add(1)
        .ok_or(EscrowError::InvalidState)?;
    state._reserved[0] = verdict;

    emit!(DealResolved { verdict });

    Ok(())
}
