const nacl = require('tweetnacl');
const fs = require('fs');
const path = require('path');

// Base58 alphabet
const BASE58_ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

function base58Encode(buffer) {
  if (buffer.length === 0) return '';
  
  let num = BigInt('0x' + Array.from(buffer)
    .map(b => b.toString(16).padStart(2, '0'))
    .join(''));
  
  let result = '';
  while (num > 0) {
    result = BASE58_ALPHABET[Number(num % 58n)] + result;
    num = num / 58n;
  }
  
  // Handle leading zeros
  for (let i = 0; i < buffer.length && buffer[i] === 0; i++) {
    result = '1' + result;
  }
  
  return result;
}

// Generate new keypair using Ed25519
const keypair = nacl.sign.keyPair();

// Convert to Solana format (64 bytes: 32 bytes secret + 32 bytes public)
const secretKey = new Uint8Array(64);
secretKey.set(keypair.secretKey.slice(0, 32), 0);
secretKey.set(keypair.publicKey, 32);

// Get the program ID (public key as base58)
const programId = base58Encode(keypair.publicKey);

// Save keypair to file (as array for Solana)
const keypairPath = path.join(__dirname, 'programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json');
const keypairDir = path.dirname(keypairPath);

// Ensure directory exists
if (!fs.existsSync(keypairDir)) {
  fs.mkdirSync(keypairDir, { recursive: true });
}

// Write keypair (array format for Solana)
fs.writeFileSync(keypairPath, JSON.stringify(Array.from(secretKey)));

console.log('✅ Generated new keypair');
console.log('📁 Saved to:', keypairPath);
console.log('🔑 New Program ID:', programId);
console.log('\nNext steps:');
console.log('1. Update lib.rs: declare_id!("' + programId + '");');
console.log('2. Update Anchor.toml: onchain_escrow = "' + programId + '"');

