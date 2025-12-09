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

// Read the keypair
const keypairPath = path.join(__dirname, 'programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json');
const keypairData = JSON.parse(fs.readFileSync(keypairPath, 'utf8'));
const secretKey = new Uint8Array(keypairData);

// Extract public key (last 32 bytes)
const publicKey = secretKey.slice(32, 64);
const programId = base58Encode(publicKey);

console.log('🔑 Program ID:', programId);
console.log('📝 Airdrop command:');
console.log(`solana airdrop 2 ${programId} --url devnet`);
console.log('\nOr use this curl command:');
console.log(`curl -X POST "https://api.devnet.solana.com" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"requestAirdrop","params":["${programId}", 2000000000]}'`);

