use anchor_lang::prelude::*;

#[error_code]
pub enum EscrowError {
    #[msg("Action not allowed in current state")] 
    InvalidState,
    #[msg("Caller not permitted")] 
    Unauthorized,
    #[msg("ResolveTicket expired")] 
    ExpiredTicket,
    #[msg("Invalid arbiter signature")] 
    SignatureInvalid,
    #[msg("Insufficient funds")] 
    InsufficientFunds,
    #[msg("Malformed or missing CID")] 
    CIDInvalid,
    #[msg("Vault account mismatch")] 
    VaultMismatch,
}

