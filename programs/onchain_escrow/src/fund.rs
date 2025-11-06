use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount, Transfer};

use crate::{EscrowError, DealFunded, EscrowStatus, EscrowState};

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

pub fn handle(ctx: Context<Fund>) -> Result<()> {
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
