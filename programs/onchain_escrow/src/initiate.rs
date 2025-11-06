use anchor_lang::prelude::*;
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token::{Mint, Token, TokenAccount};

use crate::{EscrowError, DealInitiated, EscrowStatus, EscrowState};

#[derive(Accounts)]
pub struct Initiate<'info> {
    #[account(mut)]
    pub seller: Signer<'info>,
    /// CHECK: buyer is provided by the frontend; validated on fund
    pub buyer: UncheckedAccount<'info>,
    /// CHECK: arbiter authority configured off-chain
    pub arbiter: UncheckedAccount<'info>,
    pub mint: Account<'info, Mint>,
    #[account(
        init,
        payer = seller,
        seeds = [
            b"escrow",
            seller.key().as_ref(),
            buyer.key().as_ref(),
            mint.key().as_ref(),
        ],
        bump,
        space = EscrowState::space()
    )]
    pub escrow_state: Account<'info, EscrowState>,
    /// CHECK: PDA derived for vault authority
    #[account(
        seeds = [b"vault", escrow_state.key().as_ref()],
        bump
    )]
    pub vault_authority: UncheckedAccount<'info>,
    #[account(
        init,
        payer = seller,
        associated_token::mint = mint,
        associated_token::authority = vault_authority
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub rent: Sysvar<'info, Rent>,
}

pub fn handle(
    ctx: Context<Initiate>,
    amount: u64,
    fee_bps: u16,
    dispute_by: i64,
) -> Result<()> {
    require!(amount > 0, EscrowError::InsufficientFunds);

    let now = Clock::get()?.unix_timestamp;
    let vault_bump = ctx.bumps.vault_authority;

    let state = &mut ctx.accounts.escrow_state;
    state.version = EscrowState::VERSION;
    state.bump = vault_bump;
    state.seller = ctx.accounts.seller.key();
    state.buyer = ctx.accounts.buyer.key();
    state.mint = ctx.accounts.mint.key();
    state.amount = amount;
    state.fee_bps = fee_bps;
    state.vault_ata = ctx.accounts.vault_ata.key();
    state.arbiter = ctx.accounts.arbiter.key();
    state.status = EscrowStatus::Init;
    state.nonce = 0;
    state.created_at = now;
    state.dispute_by = dispute_by;
    state._reserved = [0; 32];

    emit!(DealInitiated {
        seller: state.seller,
        buyer: state.buyer,
        mint: state.mint,
        amount,
    });

    Ok(())
}
