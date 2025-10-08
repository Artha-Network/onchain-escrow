use anchor_lang::prelude::*;
use crate::state::escrow_state::EscrowState;
use crate::events::EvidenceSubmitted;
use crate::errors::EscrowError;

#[derive(Accounts)]
pub struct SubmitEvidence<'info> {
    pub caller: Signer<'info>,
    #[account(mut)]
    pub escrow_state: Account<'info, EscrowState>,
}

pub fn handle(ctx: Context<SubmitEvidence>, cid: String) -> Result<()> {
    require!(cid.len() > 0 && cid.len() <= EscrowState::MAX_CID, EscrowError::CIDInvalid);
    let state = &mut ctx.accounts.escrow_state;
    state.evidence_cids.push(cid.clone());
    emit!(EvidenceSubmitted { deal_id: state.deal_id, cid });
    Ok(())
}

