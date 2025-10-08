use anchor_lang::prelude::*;

pub mod state { pub mod enums; pub mod price_snapshot; pub mod escrow_state; }
pub mod events;
pub mod errors;
pub mod utils;
pub mod instructions {
    pub mod initiate;
    pub mod fund;
    pub mod open_dispute;
    pub mod submit_evidence;
    pub mod resolve;
    pub mod release;
    pub mod refund;
}

declare_id!("ArthaEscrow1111111111111111111111111111111");

#[program]
pub mod onchain_escrow {
    use super::*;

    pub fn initiate(ctx: Context<instructions::initiate::Initiate>, deal_id: u128, fee_bps: u16, deliver_deadline: i64, dispute_deadline: i64) -> Result<()> {
        instructions::initiate::handle(ctx, deal_id, fee_bps, deliver_deadline, dispute_deadline)
    }

    pub fn fund(ctx: Context<instructions::fund::Fund>, amount: u64) -> Result<()> {
        instructions::fund::handle(ctx, amount)
    }

    pub fn open_dispute(ctx: Context<instructions::open_dispute::OpenDispute>) -> Result<()> {
        instructions::open_dispute::handle(ctx)
    }

    pub fn submit_evidence(ctx: Context<instructions::submit_evidence::SubmitEvidence>, cid: String) -> Result<()> {
        instructions::submit_evidence::handle(ctx, cid)
    }

    pub fn resolve(ctx: Context<instructions::resolve::Resolve>, action: instructions::resolve::ResolutionAction, nonce: u64, expires_at: i64, sig: [u8; 64]) -> Result<()> {
        instructions::resolve::handle(ctx, action, nonce, expires_at, sig)
    }

    pub fn release(ctx: Context<instructions::release::Release>) -> Result<()> {
        instructions::release::handle(ctx)
    }

    pub fn refund(ctx: Context<instructions::refund::Refund>) -> Result<()> {
        instructions::refund::handle(ctx)
    }
}

