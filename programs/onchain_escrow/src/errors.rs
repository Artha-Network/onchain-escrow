use anchor_lang::prelude::*;

#[error_code]
pub enum EscrowError {
    #[msg("Invalid stage for this operation.")]
    InvalidStage,
    #[msg("Invalid state for this operation.")]
    InvalidState,
    #[msg("Operation unauthorized.")]
    Unauthorized,
    #[msg("Invalid arbiter.")]
    InvalidArbiter,
    #[msg("Invalid verdict.")]
    InvalidVerdict,
    #[msg("Arithmetic overflow.")]
    Overflow,
    #[msg("Insufficient funds.")]
    InsufficientFunds,
    #[msg("Mint mismatch.")]
    MintMismatch,
    #[msg("Vault owner mismatch.")]
    VaultOwnerMismatch,
    #[msg("Deadline has passed.")]
    DeadlinePassed,
}
