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

// Read existing keypair or generate new one
const keypairPath = path.join(__dirname, 'programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json');
const keypairDir = path.dirname(keypairPath);

// Ensure directory exists
if (!fs.existsSync(keypairDir)) {
  fs.mkdirSync(keypairDir, { recursive: true });
}

let secretKey;
let isNew = false;

if (fs.existsSync(keypairPath)) {
  // Read existing keypair
  const keypairData = JSON.parse(fs.readFileSync(keypairPath, 'utf8'));
  secretKey = new Uint8Array(keypairData);
  console.log('📖 Read existing keypair');
} else {
  // Generate new keypair
  const keypair = nacl.sign.keyPair();
  secretKey = new Uint8Array(64);
  secretKey.set(keypair.secretKey.slice(0, 32), 0);
  secretKey.set(keypair.publicKey, 32);
  fs.writeFileSync(keypairPath, JSON.stringify(Array.from(secretKey)));
  isNew = true;
  console.log('✅ Generated new keypair');
}

// Extract public key (last 32 bytes)
const publicKey = secretKey.slice(32, 64);
const programId = base58Encode(publicKey);

console.log('🔑 Program ID:', programId);
console.log('📁 Keypair file:', keypairPath);
if (isNew) {
  console.log('\nNext steps:');
  console.log('1. Update lib.rs: declare_id!("' + programId + '");');
  console.log('2. Update Anchor.toml: onchain_escrow = "' + programId + '"');
  console.log('3. Update backend config with: ' + programId);
}

// Write to a temp file for easy access
fs.writeFileSync(path.join(__dirname, '.program-id.txt'), programId);
console.log('\n✅ Program ID saved to .program-id.txt');



