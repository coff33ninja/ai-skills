param(
    [string]$LogFile,
    [int]$MaxCorrections = 2
)

if (-not $LogFile) { Write-Host "Usage: .\check-consistency.ps1 -LogFile <session-log.txt> [-MaxCorrections 2]"; exit 1 }
if (-not (Test-Path $LogFile)) { Write-Host "[-] Log file not found: $LogFile"; exit 1 }

$lines = Get-Content -LiteralPath $LogFile

# Find correction patterns
$corrections = @()
foreach ($line in $lines) {
    if ($line -match 'correction|actually|that.s not right|wrong|incorrect|try again|redo|start over') {
        $corrections += $line
    }
}

Write-Host "=== Consistency Check ===" -ForegroundColor Cyan
Write-Host "Log: $LogFile ($($lines.Count) lines)"
Write-Host "Corrections found: $($corrections.Count)" -ForegroundColor $(if ($corrections.Count -gt $MaxCorrections) { "Red" } else { "Green" })

if ($corrections.Count -gt $MaxCorrections) {
    Write-Host "[-] Exceeded max corrections ($MaxCorrections). Consider resetting approach." -ForegroundColor Yellow
    $corrections | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "[+] Consistency within acceptable range." -ForegroundColor Green
exit 0
