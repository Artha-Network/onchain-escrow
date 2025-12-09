# Diagnostic script to verify program ID consistency
# Checks if keypair file matches declare_id!() and Anchor.toml

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Program ID Verification Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$KEYPAIR_FILE = "programs/onchain_escrow/target/deploy/onchain_escrow-keypair.json"
$LIB_RS = "programs/onchain_escrow/src/lib.rs"
$ANCHOR_TOML = "Anchor.toml"

# 1. Check if keypair file exists
Write-Host "1. Checking keypair file..." -ForegroundColor Yellow
if (Test-Path $KEYPAIR_FILE) {
    Write-Host "   ✓ Keypair file exists: $KEYPAIR_FILE" -ForegroundColor Green
    
    # Try to get pubkey from keypair file
    try {
        $keypairContent = Get-Content $KEYPAIR_FILE -Raw | ConvertFrom-Json
        Write-Host "   Keypair file contains array of length: $($keypairContent.Length)" -ForegroundColor Cyan
        
        # Note: We can't easily extract pubkey without solana-keygen, but we can check the file
        Write-Host "   ⚠ To get actual pubkey, run: solana-keygen pubkey $KEYPAIR_FILE" -ForegroundColor Yellow
    } catch {
        Write-Host "   ✗ Could not parse keypair file" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ Keypair file NOT found: $KEYPAIR_FILE" -ForegroundColor Red
    Write-Host "   This means Anchor will generate a new one on build" -ForegroundColor Yellow
}

Write-Host ""

# 2. Check declare_id!() in lib.rs
Write-Host "2. Checking declare_id!() in lib.rs..." -ForegroundColor Yellow
if (Test-Path $LIB_RS) {
    $libContent = Get-Content $LIB_RS -Raw
    if ($libContent -match 'declare_id!\("([^"]+)"\)') {
        $declareId = $matches[1]
        Write-Host "   ✓ Found declare_id!(): $declareId" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Could not find declare_id!() in lib.rs" -ForegroundColor Red
        $declareId = $null
    }
} else {
    Write-Host "   ✗ lib.rs not found" -ForegroundColor Red
    $declareId = $null
}

Write-Host ""

# 3. Check Anchor.toml
Write-Host "3. Checking Anchor.toml..." -ForegroundColor Yellow
if (Test-Path $ANCHOR_TOML) {
    $anchorContent = Get-Content $ANCHOR_TOML -Raw
    if ($anchorContent -match 'onchain_escrow = "([^"]+)"') {
        $anchorId = $matches[1]
        Write-Host "   ✓ Found program ID in Anchor.toml: $anchorId" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Could not find program ID in Anchor.toml" -ForegroundColor Red
        $anchorId = $null
    }
} else {
    Write-Host "   ✗ Anchor.toml not found" -ForegroundColor Red
    $anchorId = $null
}

Write-Host ""

# 4. Compare values
Write-Host "4. Comparing values..." -ForegroundColor Yellow
if ($declareId -and $anchorId) {
    if ($declareId -eq $anchorId) {
        Write-Host "   ✓ declare_id!() matches Anchor.toml" -ForegroundColor Green
        Write-Host "   Program ID: $declareId" -ForegroundColor Cyan
    } else {
        Write-Host "   ✗ MISMATCH DETECTED!" -ForegroundColor Red
        Write-Host "   declare_id!(): $declareId" -ForegroundColor Yellow
        Write-Host "   Anchor.toml:  $anchorId" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠ Could not compare (missing values)" -ForegroundColor Yellow
}

Write-Host ""

# 5. Check wallet config
Write-Host "5. Checking wallet configuration..." -ForegroundColor Yellow
$anchorContent = Get-Content $ANCHOR_TOML -Raw
if ($anchorContent -match 'wallet = "([^"]+)"') {
    $walletPath = $matches[1]
    Write-Host "   Wallet path in Anchor.toml: $walletPath" -ForegroundColor Cyan
    
    # Expand ~ to home directory
    if ($walletPath -like "~/*") {
        $walletPath = $walletPath -replace "~", $env:USERPROFILE
    }
    
    if (Test-Path $walletPath) {
        Write-Host "   ✓ Wallet file exists" -ForegroundColor Green
        Write-Host "   ⚠ To check wallet pubkey, run: solana-keygen pubkey `"$walletPath`"" -ForegroundColor Yellow
        Write-Host "   ⚠ IMPORTANT: Verify wallet pubkey is DIFFERENT from program ID!" -ForegroundColor Yellow
    } else {
        Write-Host "   ✗ Wallet file NOT found: $walletPath" -ForegroundColor Red
    }
}

Write-Host ""

# 6. Recommendations
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Recommendations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To verify the actual program ID from keypair file:" -ForegroundColor Yellow
Write-Host "  solana-keygen pubkey $KEYPAIR_FILE" -ForegroundColor White
Write-Host ""
Write-Host "To verify your wallet pubkey:" -ForegroundColor Yellow
Write-Host "  solana-keygen pubkey ~/.config/solana/arthadev.json" -ForegroundColor White
Write-Host ""
Write-Host "If they match, that's the problem! Your wallet keypair was used as program keypair." -ForegroundColor Red
Write-Host ""
Write-Host "To fix:" -ForegroundColor Yellow
Write-Host "  1. Generate new program keypair:" -ForegroundColor White
Write-Host "     solana-keygen new -o $KEYPAIR_FILE --no-bip39-passphrase" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Get the new pubkey:" -ForegroundColor White
Write-Host "     solana-keygen pubkey $KEYPAIR_FILE" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. Update lib.rs and Anchor.toml with the new pubkey" -ForegroundColor White
Write-Host "  4. Rebuild and redeploy" -ForegroundColor White
Write-Host ""



