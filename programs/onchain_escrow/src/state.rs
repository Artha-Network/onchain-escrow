use anchor_lang::prelude::*;

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, Debug)]
#[repr(u8)]
pub enum EscrowStatus {
    Init = 0,
    Funded = 1,
    Disputed = 2,
    Resolved = 3,
    Released = 4,
    Refunded = 5,
}

#[account]
pub struct EscrowState {
    pub version: u8,
    pub bump: u8,
    pub seller: Pubkey,
    pub buyer: Pubkey,
    pub mint: Pubkey,
    pub amount: u64,
    pub fee_bps: u16,
    pub vault_ata: Pubkey,
    pub arbiter: Pubkey,
    pub status: EscrowStatus,
    pub nonce: u64,
    pub created_at: i64,
    pub dispute_by: i64,
    pub _reserved: [u8; 32],
}

impl EscrowState {
    pub const VERSION: u8 = 1;

    pub fn space() -> usize {
        8 + core::mem::size_of::<Self>()
    }
}