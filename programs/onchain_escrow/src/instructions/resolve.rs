use anchor_lang::prelude::*;
use crate::state::escrow_state::EscrowState;
use crate::events::DealResolved;
use crate::errors::EscrowError;

#[derive(Accounts)]
pub struct Resolve<'info> {
    /// CHECK: validated via signature and allowlist (config PDA) in full impl
    pub arbiter: UncheckedAccount<'info>,
    #[account(mut)]
    pub escrow_state: Account<'info, EscrowState>,
}

pub enum ResolutionAction { Release, Refund, Split(u16 /* bps to seller */) }

pub fn handle(ctx: Context<Resolve>, action: ResolutionAction, _nonce: u64, _expires_at: i64, _sig: [u8; 64]) -> Result<()> {
    let state = &mut ctx.accounts.escrow_state;
    // TODO: verify signature + expiry + nonce using tickets-lib vector
    match action {
        ResolutionAction::Release => {
            state.status = crate::state::enums::DealStatus::Resolved;
            emit!(DealResolved { deal_id: state.deal_id, action: "Release".into() });
        }
        ResolutionAction::Refund => {
            state.status = crate::state::enums::DealStatus::Resolved;
            emit!(DealResolved { deal_id: state.deal_id, action: "Refund".into() });
        }
        ResolutionAction::Split(_bps) => {
            state.status = crate::state::enums::DealStatus::Resolved;
            emit!(DealResolved { deal_id: state.deal_id, action: "Split".into() });
        }
    }
    Ok(())
}

