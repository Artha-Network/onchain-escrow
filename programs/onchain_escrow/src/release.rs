use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount, Transfer};

use crate::{EscrowError, DealReleased, EscrowStatus, EscrowState, VERDICT_RELEASE};

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

pub fn handle(ctx: Context<Release>) -> Result<()> {
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
