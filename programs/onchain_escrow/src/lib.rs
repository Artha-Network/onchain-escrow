use anchor_lang::prelude::*;
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token::{Mint, Token, TokenAccount, Transfer};
use anchor_spl::token;

declare_id!("HM1zYGd6WVH8e73U9QZW8spamWmLqzd391raEsfiNzEZ");

pub mod errors;
pub mod events;
pub mod state;
pub mod utils;

use crate::errors::EscrowError;
use crate::events::*;
use crate::state::*;
use crate::utils::*;

#[program]
pub mod onchain_escrow_program {
    use super::*;

    pub fn initiate(
        ctx: Context<Initiate>,
        amount: u64,
        fee_bps: u16,
        dispute_by: i64,
    ) -> Result<()> {
        handle_initiate(ctx, amount, fee_bps, dispute_by)
    }

    pub fn fund(ctx: Context<Fund>) -> Result<()> {
        handle_fund(ctx)
    }

    pub fn open_dispute(ctx: Context<OpenDispute>) -> Result<()> {
        handle_open_dispute(ctx)
    }

    pub fn resolve(ctx: Context<Resolve>, verdict: u8) -> Result<()> {
        handle_resolve(ctx, verdict)
    }

    pub fn release(ctx: Context<Release>) -> Result<()> {
        handle_release(ctx)
    }

    pub fn refund(ctx: Context<Refund>) -> Result<()> {
        handle_refund(ctx)
    }
}

// --- Initiate Handler ---
#[derive(Accounts)]
pub struct Initiate<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,
    /// CHECK: seller address
    pub seller: UncheckedAccount<'info>,
    /// CHECK: buyer address
    pub buyer: UncheckedAccount<'info>,
    /// CHECK: arbiter authority configured off-chain
    pub arbiter: UncheckedAccount<'info>,
    pub mint: Account<'info, Mint>,
    #[account(
        init,
        payer = payer,
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
        payer = payer,
        associated_token::mint = mint,
        associated_token::authority = vault_authority
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub rent: Sysvar<'info, Rent>,
}

pub fn handle_initiate(
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

// --- Fund Handler ---
#[derive(Accounts)]
pub struct Fund<'info> {
    #[account(mut)]
    pub buyer: Signer<'info>,
    #[account(
        mut,
        constraint = escrow_state.buyer == buyer.key() @ EscrowError::Unauthorized,
        constraint = escrow_state.status == EscrowStatus::Init @ EscrowError::InvalidState,
        constraint = escrow_state.amount > 0 @ EscrowError::InsufficientFunds,
    )]
    pub escrow_state: Account<'info, EscrowState>,
    #[account(
        mut,
        constraint = buyer_ata.owner == buyer.key() @ EscrowError::Unauthorized,
        constraint = buyer_ata.mint == escrow_state.mint @ EscrowError::MintMismatch,
    )]
    pub buyer_ata: Account<'info, TokenAccount>,
    #[account(
        mut,
        address = escrow_state.vault_ata,
        constraint = vault_ata.mint == escrow_state.mint @ EscrowError::MintMismatch,
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
}

pub fn handle_fund(ctx: Context<Fund>) -> Result<()> {
    let expected_vault = ctx.accounts.vault_authority_key()?;
    let state = &mut ctx.accounts.escrow_state;
    require_keys_eq!(
        ctx.accounts.vault_ata.owner,
        expected_vault,
        EscrowError::VaultOwnerMismatch
    );

    let amount = state.amount;
    require!(amount > 0, EscrowError::InsufficientFunds);
    require!(
        ctx.accounts.buyer_ata.amount >= amount,
        EscrowError::InsufficientFunds
    );

    let transfer_accounts = Transfer {
        from: ctx.accounts.buyer_ata.to_account_info(),
        to: ctx.accounts.vault_ata.to_account_info(),
        authority: ctx.accounts.buyer.to_account_info(),
    };
    let cpi_ctx = CpiContext::new(ctx.accounts.token_program.to_account_info(), transfer_accounts);
    token::transfer(cpi_ctx, amount)?;

    state.status = EscrowStatus::Funded;

    emit!(DealFunded {
        buyer: state.buyer,
        amount,
    });

    Ok(())
}

impl<'info> Fund<'info> {
    fn vault_authority_key(&self) -> Result<Pubkey> {
        Pubkey::create_program_address(
            &[b"vault", self.escrow_state.key().as_ref(), &[self.escrow_state.bump]],
            &crate::ID,
        )
        .map_err(|_| error!(EscrowError::VaultOwnerMismatch))
    }
}

// --- Open Dispute Handler ---
#[derive(Accounts)]
pub struct OpenDispute<'info> {
    pub caller: Signer<'info>,
    #[account(
        mut,
        constraint = escrow_state.status == EscrowStatus::Funded @ EscrowError::InvalidState,
    )]
    pub escrow_state: Account<'info, EscrowState>,
}

pub fn handle_open_dispute(ctx: Context<OpenDispute>) -> Result<()> {
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

// --- Resolve Handler ---
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

pub fn handle_resolve(ctx: Context<Resolve>, verdict: u8) -> Result<()> {
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

// --- Release Handler ---
#[derive(Accounts)]
pub struct Release<'info> {
    #[account(mut)]
    pub seller: Signer<'info>,
    #[account(
        mut,
        constraint = escrow_state.seller == seller.key() @ EscrowError::Unauthorized,
        constraint = escrow_state.status == EscrowStatus::Resolved @ EscrowError::InvalidState,
    )]
    pub escrow_state: Account<'info, EscrowState>,
    /// CHECK: PDA authority for the vault
    pub vault_authority: UncheckedAccount<'info>,
    #[account(
        mut,
        address = escrow_state.vault_ata,
        constraint = vault_ata.mint == escrow_state.mint @ EscrowError::MintMismatch,
        constraint = vault_ata.owner == vault_authority.key() @ EscrowError::VaultOwnerMismatch,
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    #[account(
        mut,
        constraint = seller_ata.owner == seller.key() @ EscrowError::Unauthorized,
        constraint = seller_ata.mint == escrow_state.mint @ EscrowError::MintMismatch,
    )]
    pub seller_ata: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
}

pub fn handle_release(ctx: Context<Release>) -> Result<()> {
    let escrow_state_key = ctx.accounts.escrow_state.key();
    let bump = ctx.accounts.escrow_state.bump;
    let bump_seed = [bump];
    let seeds: [&[u8]; 3] = [
        b"vault".as_ref(),
        escrow_state_key.as_ref(),
        bump_seed.as_ref(),
    ];
    let signer_seeds: [&[&[u8]]; 1] = [&seeds];

    let expected_vault = Pubkey::create_program_address(&seeds, &crate::ID)
        .map_err(|_| error!(EscrowError::VaultOwnerMismatch))?;
    require_keys_eq!(
        ctx.accounts.vault_authority.key(),
        expected_vault,
        EscrowError::VaultOwnerMismatch
    );

    let state = &mut ctx.accounts.escrow_state;
    require!(state._reserved[0] == VERDICT_RELEASE, EscrowError::InvalidState);
    let amount = state.amount;
    require!(amount > 0, EscrowError::InsufficientFunds);
    require!(
        ctx.accounts.vault_ata.amount >= amount,
        EscrowError::InsufficientFunds
    );

    let transfer_accounts = Transfer {
        from: ctx.accounts.vault_ata.to_account_info(),
        to: ctx.accounts.seller_ata.to_account_info(),
        authority: ctx.accounts.vault_authority.to_account_info(),
    };
    let cpi_ctx = CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        transfer_accounts,
        &signer_seeds,
    );
    token::transfer(cpi_ctx, amount)?;

    state.amount = 0;
    state.status = EscrowStatus::Released;

    emit!(DealReleased { amount });

    Ok(())
}

// --- Refund Handler ---
#[derive(Accounts)]
pub struct Refund<'info> {
    #[account(mut)]
    pub buyer: Signer<'info>,
    #[account(
        mut,
        constraint = escrow_state.buyer == buyer.key() @ EscrowError::Unauthorized,
        constraint = escrow_state.status == EscrowStatus::Resolved @ EscrowError::InvalidState,
    )]
    pub escrow_state: Account<'info, EscrowState>,
    /// CHECK: PDA authority for the vault
    pub vault_authority: UncheckedAccount<'info>,
    #[account(
        mut,
        address = escrow_state.vault_ata,
        constraint = vault_ata.mint == escrow_state.mint @ EscrowError::MintMismatch,
        constraint = vault_ata.owner == vault_authority.key() @ EscrowError::VaultOwnerMismatch,
    )]
    pub vault_ata: Account<'info, TokenAccount>,
    #[account(
        mut,
        constraint = buyer_ata.owner == buyer.key() @ EscrowError::Unauthorized,
        constraint = buyer_ata.mint == escrow_state.mint @ EscrowError::MintMismatch,
    )]
    pub buyer_ata: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
}

pub fn handle_refund(ctx: Context<Refund>) -> Result<()> {
    let escrow_state_key = ctx.accounts.escrow_state.key();
    let bump = ctx.accounts.escrow_state.bump;
    let bump_seed = [bump];
    let seeds: [&[u8]; 3] = [
        b"vault".as_ref(),
        escrow_state_key.as_ref(),
        bump_seed.as_ref(),
    ];
    let signer_seeds: [&[&[u8]]; 1] = [&seeds];

    let expected_vault = Pubkey::create_program_address(&seeds, &crate::ID)
        .map_err(|_| error!(EscrowError::VaultOwnerMismatch))?;
    require_keys_eq!(
        ctx.accounts.vault_authority.key(),
        expected_vault,
        EscrowError::VaultOwnerMismatch
    );

    let state = &mut ctx.accounts.escrow_state;
    require!(state._reserved[0] == VERDICT_REFUND, EscrowError::InvalidState);

    let amount = state.amount;
    require!(amount > 0, EscrowError::InsufficientFunds);
    require!(
        ctx.accounts.vault_ata.amount >= amount,
        EscrowError::InsufficientFunds
    );

    let transfer_accounts = Transfer {
        from: ctx.accounts.vault_ata.to_account_info(),
        to: ctx.accounts.buyer_ata.to_account_info(),
        authority: ctx.accounts.vault_authority.to_account_info(),
    };
    let cpi_ctx = CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        transfer_accounts,
        &signer_seeds,
    );
    token::transfer(cpi_ctx, amount)?;

    state.amount = 0;
    state.status = EscrowStatus::Refunded;

    emit!(DealRefunded { amount });

    Ok(())
}
