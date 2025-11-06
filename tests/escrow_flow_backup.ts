import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { strict as assert } from "assert";
import {
  ASSOCIATED_TOKEN_PROGRAM_ID,
  TOKEN_PROGRAM_ID,
  createMint,
  getAccount,
  getAssociatedTokenAddressSync,
  getOrCreateAssociatedTokenAccount,
  mintTo,
} from "@solana/spl-token";
import { PublicKey, SystemProgram, SYSVAR_RENT_PUBKEY } from "@solana/web3.js";

import { OnchainEscrow } from "../target/types/onchain_escrow";
import { getMockArbiterKeypair } from "./arbiter_keypair";

const VERDICT_RELEASE = 1;
const VERDICT_REFUND = 2;

describe("onchain-escrow", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const program = anchor.workspace.OnchainEscrow as Program<OnchainEscrow>;
  const payer = (provider.wallet as any).payer as anchor.web3.Keypair;

  async function airdrop(pubkey: PublicKey, lamports = 2 * anchor.web3.LAMPORTS_PER_SOL) {
    const signature = await provider.connection.requestAirdrop(pubkey, lamports);
    await provider.connection.confirmTransaction(signature, "confirmed");
  }

  async function setupEscrowFixture(amount: number) {
    const seller = anchor.web3.Keypair.generate();
    const buyer = anchor.web3.Keypair.generate();
    const arbiter = getMockArbiterKeypair(); // Use deterministic mock arbiter

    await Promise.all([
      airdrop(seller.publicKey),
      airdrop(buyer.publicKey),
      airdrop(arbiter.publicKey),
    ]);

    const mint = await createMint(
      provider.connection,
      payer,
      payer.publicKey,
      null,
      0,
    );

    const buyerAta = await getOrCreateAssociatedTokenAccount(
      provider.connection,
      payer,
      mint,
      buyer.publicKey,
    );

    const sellerAta = await getOrCreateAssociatedTokenAccount(
      provider.connection,
      payer,
      mint,
      seller.publicKey,
    );

    await mintTo(
      provider.connection,
      payer,
      mint,
      buyerAta.address,
      payer,
      amount,
    );

    const [escrowState] = PublicKey.findProgramAddressSync(
      [
        Buffer.from("escrow"),
        seller.publicKey.toBuffer(),
        buyer.publicKey.toBuffer(),
        mint.toBuffer(),
      ],
      program.programId,
    );

    const [vaultAuthority] = PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), escrowState.toBuffer()],
      program.programId,
    );

    const vaultAta = getAssociatedTokenAddressSync(mint, vaultAuthority, true);

    await program.methods
      .initiate(new anchor.BN(amount), 0, new anchor.BN(0))
      .accounts({
        seller: seller.publicKey,
        buyer: buyer.publicKey,
        arbiter: arbiter.publicKey,
        mint,
        escrowState,
        vaultAuthority,
        vaultAta,
        systemProgram: SystemProgram.programId,
        tokenProgram: TOKEN_PROGRAM_ID,
        associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
        rent: SYSVAR_RENT_PUBKEY,
      })
      .signers([seller])
      .rpc();

    return {
      amount,
      seller,
      buyer,
      arbiter,
      mint,
      escrowState,
      vaultAuthority,
      vaultAta,
      buyerAta: buyerAta.address,
      sellerAta: sellerAta.address,
    };
  }

  it("happy path release", async () => {
    const amount = 100;
    const fixture = await setupEscrowFixture(amount);

    await program.methods
      .fund()
      .accounts({
        buyer: fixture.buyer.publicKey,
        escrowState: fixture.escrowState,
        buyerAta: fixture.buyerAta,
        vaultAta: fixture.vaultAta,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([fixture.buyer])
      .rpc();

    await program.methods
      .resolve(VERDICT_RELEASE)
      .accounts({
        arbiter: fixture.arbiter.publicKey,
        escrowState: fixture.escrowState,
      })
      .signers([fixture.arbiter])
      .rpc();

    await program.methods
      .release()
      .accounts({
        seller: fixture.seller.publicKey,
        escrowState: fixture.escrowState,
        vaultAuthority: fixture.vaultAuthority,
        vaultAta: fixture.vaultAta,
        sellerAta: fixture.sellerAta,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([fixture.seller])
      .rpc();

    const sellerAtaAfter = await getAccount(provider.connection, fixture.sellerAta);
    const vaultAtaAfter = await getAccount(provider.connection, fixture.vaultAta);

    assert.equal(Number(sellerAtaAfter.amount), amount);
    assert.equal(Number(vaultAtaAfter.amount), 0);
  });

  it("rejects unauthorized fund and resolve", async () => {
    const amount = 75;
    const fixture = await setupEscrowFixture(amount);

    await assert.rejects(
      program.methods
        .fund()
        .accounts({
          buyer: fixture.seller.publicKey,
          escrowState: fixture.escrowState,
          buyerAta: fixture.buyerAta,
          vaultAta: fixture.vaultAta,
          tokenProgram: TOKEN_PROGRAM_ID,
        })
        .signers([fixture.seller])
        .rpc(),
      /Unauthorized signer/,
    );

    await program.methods
      .fund()
      .accounts({
        buyer: fixture.buyer.publicKey,
        escrowState: fixture.escrowState,
        buyerAta: fixture.buyerAta,
        vaultAta: fixture.vaultAta,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([fixture.buyer])
      .rpc();

    await assert.rejects(
      program.methods
        .resolve(VERDICT_RELEASE)
        .accounts({
          arbiter: fixture.buyer.publicKey,
          escrowState: fixture.escrowState,
        })
        .signers([fixture.buyer])
        .rpc(),
      /Unauthorized signer/,
    );
  });

  it("refund path returns funds to buyer", async () => {
    const amount = 60;
    const fixture = await setupEscrowFixture(amount);

    await program.methods
      .fund()
      .accounts({
        buyer: fixture.buyer.publicKey,
        escrowState: fixture.escrowState,
        buyerAta: fixture.buyerAta,
        vaultAta: fixture.vaultAta,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([fixture.buyer])
      .rpc();

    await program.methods
      .resolve(VERDICT_REFUND)
      .accounts({
        arbiter: fixture.arbiter.publicKey,
        escrowState: fixture.escrowState,
      })
      .signers([fixture.arbiter])
      .rpc();

    await program.methods
      .refund()
      .accounts({
        buyer: fixture.buyer.publicKey,
        escrowState: fixture.escrowState,
        vaultAuthority: fixture.vaultAuthority,
        vaultAta: fixture.vaultAta,
        buyerAta: fixture.buyerAta,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([fixture.buyer])
      .rpc();

    const buyerAtaAfter = await getAccount(provider.connection, fixture.buyerAta);
    const vaultAtaAfter = await getAccount(provider.connection, fixture.vaultAta);

    assert.equal(Number(buyerAtaAfter.amount), amount);
    assert.equal(Number(vaultAtaAfter.amount), 0);
  });

  it("end-to-end dispute flow with mock arbiter", async () => {
    const amount = 1000;
    const fixture = await setupEscrowFixture(amount);

    // 1. Initiate escrow
    await program.methods
      .initiate(new anchor.BN(amount), 250, Date.now() / 1000 + 86400)
      .accounts({
        seller: fixture.seller.publicKey,
        buyer: fixture.buyer.publicKey,
        arbiter: fixture.arbiter.publicKey,
        mint: fixture.mint,
        escrowState: fixture.escrowState,
        vaultAuthority: fixture.vaultAuthority,
        vaultAta: fixture.vaultAta,
        systemProgram: SystemProgram.programId,
        tokenProgram: TOKEN_PROGRAM_ID,
        associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
        rent: SYSVAR_RENT_PUBKEY,
      })
      .signers([fixture.seller])
      .rpc();

    // 2. Fund escrow
    await program.methods
      .fund()
      .accounts({
        buyer: fixture.buyer.publicKey,
        escrowState: fixture.escrowState,
        buyerAta: fixture.buyerAta,
        vaultAta: fixture.vaultAta,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([fixture.buyer])
      .rpc();

    // 3. Open dispute
    await program.methods
      .openDispute()
      .accounts({
        caller: fixture.buyer.publicKey,
        escrowState: fixture.escrowState,
      })
      .signers([fixture.buyer])
      .rpc();

    // 4. Resolve dispute (arbiter decides to refund)
    await program.methods
      .resolve(VERDICT_REFUND)
      .accounts({
        arbiter: fixture.arbiter.publicKey,
        escrowState: fixture.escrowState,
      })
      .signers([fixture.arbiter])
      .rpc();

    // 5. Execute refund
    await program.methods
      .refund()
      .accounts({
        buyer: fixture.buyer.publicKey,
        escrowState: fixture.escrowState,
        vaultAuthority: fixture.vaultAuthority,
        vaultAta: fixture.vaultAta,
        buyerAta: fixture.buyerAta,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([fixture.buyer])
      .rpc();

    // Verify final state
    const state = await program.account.escrowState.fetch(fixture.escrowState);
    assert.equal(state.status.refunded, undefined); // Check status is Refunded
    
    const buyerAtaAfter = await getAccount(provider.connection, fixture.buyerAta);
    assert.equal(Number(buyerAtaAfter.amount), amount); // Buyer got refunded
  });
});