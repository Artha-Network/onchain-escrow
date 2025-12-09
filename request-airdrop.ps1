# PowerShell script to request airdrop for the new program ID

$PROGRAM_ID = "B1a1oejNg8uWz7USuuFSqmRQRUSZ95kk2e4PzRZ7Uti4"
$RPC_URL = "https://api.devnet.solana.com"

Write-Host "Requesting airdrop for program ID: $PROGRAM_ID" -ForegroundColor Green

$body = @{
    jsonrpc = "2.0"
    id = 1
    method = "requestAirdrop"
    params = @($PROGRAM_ID, 2000000000)
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $RPC_URL -Method Post -Body $body -ContentType "application/json"
    
    if ($response.result) {
        Write-Host "✅ Airdrop requested successfully!" -ForegroundColor Green
        Write-Host "Signature: $($response.result)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Waiting for confirmation..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Check balance
        $balanceBody = @{
            jsonrpc = "2.0"
            id = 1
            method = "getBalance"
            params = @($PROGRAM_ID)
        } | ConvertTo-Json
        
        $balanceResponse = Invoke-RestMethod -Uri $RPC_URL -Method Post -Body $balanceBody -ContentType "application/json"
        $balance = $balanceResponse.result.value / 1000000000
        
        Write-Host "Current balance: $balance SOL" -ForegroundColor Green
    } else {
        Write-Host "❌ Airdrop failed: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error requesting airdrop: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can also use the Solana CLI:" -ForegroundColor Yellow
    Write-Host "solana airdrop 2 $PROGRAM_ID --url devnet" -ForegroundColor Cyan
}

