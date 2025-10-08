use anchor_lang::prelude::*;
use crate::state::escrow_state::EscrowState;
use crate::events::DealInitiated;

#[derive(Accounts)]
#[instruction(deal_id: u128)]
pub struct Initiate<'info> {
    #[account(mut)]
    pub seller: Signer<'info>,
    /// CHECK: buyer may be verified later
    pub buyer: UncheckedAccount<'info>,
    #[account(
        init,
        payer = seller,
        seeds = [b"escrow", &deal_id.to_be_bytes()],
        bump,
        space = 8 + EscrowState::space()
    )]
    pub escrow_state: Account<'info, EscrowState>,
    pub system_program: Program<'info, System>,
}

pub fn handle(ctx: Context<Initiate>, deal_id: u128, _fee_bps: u16, _deliver_deadline: i64, _dispute_deadline: i64) -> Result<()> {
    let state = &mut ctx.accounts.escrow_state;
    state.deal_id = deal_id;
    state.seller = ctx.accounts.seller.key();
    state.buyer = ctx.accounts.buyer.key();
    state.created_at = Clock::get()?.unix_timestamp;
    state.status = crate::state::enums::DealStatus::Init;
    emit!(DealInitiated { deal_id });
    Ok(())
}

