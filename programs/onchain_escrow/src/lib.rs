use anchor_lang::prelude::*;

declare_id!("E4Vq17qHGG1PFr5h6vZdQUb3nxhjJB9dwMijiVdxfZLd");

// Module declarations
pub mod errors;
pub mod events;
pub mod state;
pub mod utils;

// Re-export everything from modules
pub use errors::*;
pub use events::*;
pub use state::*;
pub use utils::*;

// Instruction modules - flatten the structure for Anchor
pub mod initiate;
pub mod fund;
pub mod open_dispute;
pub mod resolve;
pub mod release;
pub mod refund;

// Re-export the contexts
pub use initiate::*;
pub use fund::*;
pub use open_dispute::*;
pub use resolve::*;
pub use release::*;
pub use refund::*;

#[program]
pub mod onchain_escrow {
    use super::*;

    pub fn initiate(
        ctx: Context<Initiate>,
        amount: u64,
        fee_bps: u16,
        dispute_by: i64,
    ) -> Result<()> {
        initiate::handle(ctx, amount, fee_bps, dispute_by)
    }

    pub fn fund(ctx: Context<Fund>) -> Result<()> {
        fund::handle(ctx)
    }

    pub fn open_dispute(ctx: Context<OpenDispute>) -> Result<()> {
        open_dispute::handle(ctx)
    }

    pub fn resolve(ctx: Context<Resolve>, verdict: u8) -> Result<()> {
        resolve::handle(ctx, verdict)
    }

    pub fn release(ctx: Context<Release>) -> Result<()> {
        release::handle(ctx)
    }

    pub fn refund(ctx: Context<Refund>) -> Result<()> {
        refund::handle(ctx)
    }
}
