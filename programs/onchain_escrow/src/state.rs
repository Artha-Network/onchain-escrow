use anchor_lang::prelude::*;

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, Debug)]
pub enum EscrowStatus {
    Init,
    Funded,
    Disputed,
    Resolved,
    Released,
    Refunded,
}

#[account]
pub struct EscrowState {
    pub version: u8,
    pub seller: Pubkey,
    pub buyer: Pubkey,
    pub arbiter: Pubkey,
    pub mint: Pubkey,
    pub vault_ata: Pubkey,
    pub amount: u64,
    pub fee_bps: u16,
    pub dispute_by: i64,
    pub status: EscrowStatus,
    pub nonce: u64,
    pub created_at: i64,
    pub winner: Pubkey, // Set when resolved
    pub bump: u8,
    pub _reserved: [u8; 32],
}

impl EscrowState {
    pub const VERSION: u8 = 1;
    
    pub const LEN: usize = 8 + // discriminator
        1 + // version
        32 + // seller
        32 + // buyer
        32 + // arbiter
        32 + // mint
        32 + // vault_ata
        8 + // amount
        2 + // fee_bps
        8 + // dispute_by
        1 + // status (enum)
        8 + // nonce
        8 + // created_at
        32 + // winner
        1 + // bump
        32; // _reserved
    
    pub fn space() -> usize {
        Self::LEN
    }
}