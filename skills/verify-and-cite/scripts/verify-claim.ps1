param(
    [string]$Claim,
    [string]$SourceFile,
    [string]$Url,
    [switch]$Json
)

if (-not $Claim -and -not $SourceFile -and -not $Url) {
    Write-Host "Usage:"
    Write-Host "  .\verify-claim.ps1 -Claim 'some statement'"
    Write-Host "  .\verify-claim.ps1 -SourceFile 'path/to/file' -Claim 'symbol or text'"
    Write-Host "  .\verify-claim.ps1 -Url 'https://...'"
    exit 1
}

$result = @{Claim=$Claim; Verified=$false; Source=$null; Confidence=0}

if ($SourceFile -and (Test-Path $SourceFile)) {
    $content = Get-Content -LiteralPath $SourceFile -Raw
    if ($content -match [regex]::Escape($Claim)) {
        $result.Verified = $true
        $result.Source = $SourceFile
        $result.Confidence = 100
        Write-Host "[+] CLAIM VERIFIED in $SourceFile" -ForegroundColor Green
    } else {
        $result.Source = $SourceFile
        $result.Confidence = 0
        Write-Host "[-] Claim NOT found in $SourceFile" -ForegroundColor Red
    }
}

if ($Claim -and -not $SourceFile) {
    Write-Host "[-] No source provided for claim. Use -SourceFile or -Url" -ForegroundColor Yellow
    $result.Confidence = 0
}

if ($Url) {
    try {
        $resp = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -UseBasicParsing -Method Head
        $result.Verified = $resp.StatusCode -eq 200
        $result.Source = $Url
        Write-Host "[+] URL reachable: $Url (HTTP $($resp.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "[-] URL error: $_" -ForegroundColor Red
        $result.Source = $Url
    }
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json)
}
exit $(if ($result.Verified) { 0 } else { 1 })
