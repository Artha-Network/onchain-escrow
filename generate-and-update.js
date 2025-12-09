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

// Generate new keypair
const keypair = nacl.sign.keyPair();
const secretKey = new Uint8Array(64);
secretKey.set(keypair.secretKey.slice(0, 32), 0);
secretKey.set(keypair.publicKey, 32);

// Get program ID
const programId = base58Encode(keypair.publicKey);

// Save keypair
const keypairPath = path.join(__dirname, 'programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json');
const keypairDir = path.dirname(keypairPath);
if (!fs.existsSync(keypairDir)) {
  fs.mkdirSync(keypairDir, { recursive: true });
}
fs.writeFileSync(keypairPath, JSON.stringify(Array.from(secretKey)));

// Update lib.rs
const libRsPath = path.join(__dirname, 'programs/onchain_escrow/src/lib.rs');
let libRs = fs.readFileSync(libRsPath, 'utf8');
libRs = libRs.replace(/declare_id!\("[^"]+"\);/, `declare_id!("${programId}");`);
fs.writeFileSync(libRsPath, libRs);

// Update Anchor.toml
const anchorTomlPath = path.join(__dirname, 'Anchor.toml');
let anchorToml = fs.readFileSync(anchorTomlPath, 'utf8');
anchorToml = anchorToml.replace(/onchain_escrow = "[^"]+"/, `onchain_escrow = "${programId}"`);
fs.writeFileSync(anchorTomlPath, anchorToml);

// Update backend config
const backendConfigPath = path.join(__dirname, '../actions-server/src/config/solana.ts');
if (fs.existsSync(backendConfigPath)) {
  let backendConfig = fs.readFileSync(backendConfigPath, 'utf8');
  backendConfig = backendConfig.replace(/const DEFAULT_PROGRAM_ID = "[^"]+";/, `const DEFAULT_PROGRAM_ID = "${programId}";`);
  fs.writeFileSync(backendConfigPath, backendConfig);
}

// Update airdrop script
const airdropScriptPath = path.join(__dirname, 'request-airdrop.ps1');
if (fs.existsSync(airdropScriptPath)) {
  let airdropScript = fs.readFileSync(airdropScriptPath, 'utf8');
  airdropScript = airdropScript.replace(/\$PROGRAM_ID = "[^"]+"/, `$PROGRAM_ID = "${programId}"`);
  fs.writeFileSync(airdropScriptPath, airdropScript);
}

console.log('✅ Generated new keypair');
console.log('🔑 New Program ID:', programId);
console.log('📁 Keypair saved to:', keypairPath);
console.log('');
console.log('✅ Updated files:');
console.log('  - programs/onchain_escrow/src/lib.rs');
console.log('  - Anchor.toml');
console.log('  - actions-server/src/config/solana.ts');
console.log('  - request-airdrop.ps1');
console.log('');
console.log('Next steps:');
console.log('1. Request airdrop: .\\request-airdrop.ps1');
console.log('2. Build: anchor build');
console.log('3. Deploy: anchor deploy --provider.cluster devnet');



