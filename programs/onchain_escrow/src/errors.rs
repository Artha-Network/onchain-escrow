use anchor_lang::prelude::*;

#[error_code]
pub enum EscrowError {
    #[msg("Unauthorized signer")]
    Unauthorized,
    #[msg("Invalid state transition")]
    InvalidState,
    #[msg("Mint or ATA mismatch")]
    MintMismatch,
    #[msg("Insufficient funds")]
    InsufficientFunds,
    #[msg("Dispute deadline passed")]
    DeadlinePassed,
    #[msg("Vault authority mismatch")]
    VaultOwnerMismatch,
}
